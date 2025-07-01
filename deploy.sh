#!/usr/bin/env bash
# Deploy a low‑cost, HA load‑balanced web tier on Azure.
# Requires Azure CLI + jq. Tested on Ubuntu 24.04 LTS (WSL‑2).
set -euo pipefail

########################################
# User‑modifiable defaults (override via .env)
########################################
LOCATION="eastus"                # Region (zones 1‑3 supported)
RG="demo-halbrg"               # Resource Group
PREFIX="halbdemo"               # Naming prefix
VM_SIZE="Standard_B1s"          # FinOps‑friendly burstable size
ADMIN_USER="azureuser"
TAGS=(Project=Demo-HALB Environment=Dev Owner=$(whoami) CostCenter=CC-1234 CreateDate=$(date +%F))
DEPLOY_USE_SPOT=${DEPLOY_USE_SPOT:-false} # Spot‑VM toggle
ENABLE_JIT=${ENABLE_JIT:-false}           # JIT Access toggle

# Load .env overrides if present
[[ -f .env ]] && source .env

########################################
# Helper: Tag arguments builder
########################################
build_tags() {
  local tag_args=()
  for t in "${TAGS[@]}"; do
    tag_args+=( --tags "$t" )
  done
  echo "${tag_args[@]}"
}
TAG_ARGS=$(build_tags)

########################################
# 1) Create Resource Group
########################################
az group create --name "$RG" --location "$LOCATION" $TAG_ARGS

########################################
# 2) Networking + LB
########################################
VNET="$PREFIX-vnet"
SUBNET="web"
NSG="$PREFIX-nsg"
PIP="$PREFIX-pip"
LB="$PREFIX-lb"
BACKEND_POOL="$PREFIX-bepool"
HEALTH_PROBE="$PREFIX-probe"
LB_RULE="$PREFIX-http"

az network vnet create \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --name "$VNET" \
  --address-prefix 10.0.0.0/16 \
  --subnet-name "$SUBNET" \
  --subnet-prefix 10.0.1.0/24 $TAG_ARGS

az network nsg create --resource-group "$RG" --name "$NSG" --location "$LOCATION" $TAG_ARGS

# Allow HTTP from anywhere; SSH only from caller IP
CALLER_IP=$(curl -s https://api.ipify.org)
az network nsg rule create --resource-group "$RG" --nsg-name "$NSG" --name Allow-HTTP --priority 100 \
  --destination-port-ranges 80 --direction Inbound --access Allow --protocol Tcp
az network nsg rule create --resource-group "$RG" --nsg-name "$NSG" --name Allow-SSH --priority 110 \
  --destination-port-ranges 22 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "$CALLER_IP/32"

az network public-ip create --resource-group "$RG" --name "$PIP" --sku Standard --allocation-method Static --location "$LOCATION" $TAG_ARGS

az network lb create --resource-group "$RG" --name "$LB" --sku Standard \
  --public-ip-address "$PIP" --frontend-ip-name "$PREFIX-fe" --backend-pool-name "$BACKEND_POOL" --location "$LOCATION" $TAG_ARGS

az network lb probe create --resource-group "$RG" --lb-name "$LB" --name "$HEALTH_PROBE" --protocol Tcp --port 80

az network lb rule create --resource-group "$RG" --lb-name "$LB" --name "$LB_RULE" \
  --protocol Tcp --frontend-port 80 --backend-port 80 \
  --frontend-ip-name "$PREFIX-fe" --backend-pool-name "$BACKEND_POOL" --probe-name "$HEALTH_PROBE" --load-distribution SourceIPProtocol

########################################
# 3) High Availability Set / Zones
########################################
AVSET="$PREFIX-avset"
REGION_ZONES=$(az vm list-skus --zone --location "$LOCATION" --query "[?name=='$VM_SIZE'].locationInfo[0].zones[] | [0]" -o tsv || true)

USE_ZONES=false
if [[ -n "$REGION_ZONES" ]]; then
  USE_ZONES=true
fi

########################################
# 4) Create SSH key if missing (local)
########################################
SSH_KEY="$HOME/.ssh/id_rsa.pub"
if [[ ! -f $SSH_KEY ]]; then
  echo "SSH key not found, generating..."
  ssh-keygen -t rsa -b 4096 -f "${SSH_KEY%.pub}" -N ""
fi

########################################
# 5) Deploy VMs (using pre‑created NIC so it can be attached to LB)
########################################
USERDATA_FILE=$(mktemp)
cat <<'CLOUD' > "$USERDATA_FILE"
#cloud-config
package_update: true
package_upgrade: true
packages:
  - nginx
runcmd:
  - systemctl enable --now nginx
  - echo "<h1>Azure HA LB Demo $(hostname)</h1>" > /var/www/html/index.html
CLOUD

for i in 1 2; do
  VM_NAME="$PREFIX-vm$i"
  NIC="$VM_NAME-nic"

  # Create NIC first, so we can explicitly associate it to LB & NSG
  az network nic create \
    --resource-group "$RG" \
    --name "$NIC" \
    --vnet-name "$VNET" \
    --subnet "$SUBNET" \
    --network-security-group "$NSG" \
    --accelerated-networking false \
    $TAG_ARGS >/dev/null

  # VM creation –‑‑> **explicitly attach NIC**
  if [ "$USE_ZONES" = true ]; then
    ZONE=$i
    az vm create --resource-group "$RG" --name "$VM_NAME" --size "$VM_SIZE" --image Ubuntu2204 \
      --admin-username "$ADMIN_USER" --ssh-key-values "$SSH_KEY" --zone "$ZONE" \
      --nics "$NIC" \
      --custom-data "$USERDATA_FILE" $( [ "$DEPLOY_USE_SPOT" = true ] && echo "--priority Spot --max-price -1" ) $TAG_ARGS >/dev/null
  else
    # Create Availability Set once
    if ! az vm availability-set show -g "$RG" -n "$AVSET" &>/dev/null; then
      az vm availability-set create -g "$RG" -n "$AVSET" --platform-fault-domain-count 2 --platform-update-domain-count 2 $TAG_ARGS >/dev/null
    fi
    az vm create --resource-group "$RG" --name "$VM_NAME" --size "$VM_SIZE" --image Ubuntu2204 \
      --admin-username "$ADMIN_USER" --ssh-key-values "$SSH_KEY" --availability-set "$AVSET" \
      --nics "$NIC" \
      --custom-data "$USERDATA_FILE" $( [ "$DEPLOY_USE_SPOT" = true ] && echo "--priority Spot --max-price -1" ) $TAG_ARGS >/dev/null
  fi

  # Attach NIC to backend pool
  az network nic ip-config address-pool add \
    --address-pool "$BACKEND_POOL" \
    --ip-config-name ipconfig1 \
    --nic-name "$NIC" \
    --resource-group "$RG" \
    --lb-name "$LB" >/dev/null

done

########################################
# 6) Output
########################################
LB_IP=$(az network public-ip show --resource-group "$RG" --name "$PIP" --query ipAddress -o tsv)

cat <<EOF

Deployment complete!
Your demo site should be reachable at: http://$LB_IP  (give it ~2‑3 min for the health probes to pass)
EOF

# Clean up temp file
rm "$USERDATA_FILE"
