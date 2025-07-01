#!/bin/bash
set -e

RG="rg-nlb-lab"
LOCATION="eastus"
VNET="vnet-nlb"
SUBNET="subnet-nlb"
NSG="nsg-nlb"
AVSET="avset-nlb"
LB="lb-nlb"
FRONT="lb-front"
BACKEND="lb-backend"
PROBE="http-probe"
RULE="lb-rule-http"

echo "🔐 Autenticando..."
az login -o none

echo "🔧 Creando grupo de recursos..."
az group create -n $RG -l $LOCATION --tags autor=gmtech proyecto=lab_nlb_ha -o none

echo "🌐 VNet y subred..."
az network vnet create -g $RG -n $VNET -l $LOCATION --address-prefix 10.20.0.0/16         --subnet-name $SUBNET --subnet-prefix 10.20.1.0/24 -o none

echo "🧱 Availability set..."
az vm availability-set create -g $RG -n $AVSET --platform-fault-domain-count 2 --platform-update-domain-count 2 -o none

echo "🔒 NSG y regla 80..."
az network nsg create -g $RG -n $NSG -o none
az network nsg rule create -g $RG --nsg-name $NSG -n Allow80 --priority 1000 --access Allow         --protocol Tcp --direction Inbound --destination-port-ranges 80 -o none

echo "🌐 IP pública..."
az network public-ip create -g $RG -n pip-nlb --sku Basic --allocation-method Static -o none

echo "🧱 Load Balancer..."
az network lb create -g $RG -n $LB --sku Basic --public-ip-address pip-nlb         --frontend-ip-name $FRONT --backend-pool-name $BACKEND -o none

echo "📡 Probe HTTP..."
az network lb probe create -g $RG --lb-name $LB -n $PROBE --protocol Http --port 80 --path / --interval 15 -o none

echo "⚙️ Regla de balanceo..."
az network lb rule create -g $RG --lb-name $LB -n $RULE --protocol Tcp --frontend-port 80 --backend-port 80         --frontend-ip-name $FRONT --backend-pool-name $BACKEND --probe-name $PROBE -o none

for i in 1 2; do
  VM="vm${i}"
  echo "🖥️ Creando $VM..."
  az vm create -g $RG -n $VM --image Ubuntu2204 --size Standard_B1s --vnet-name $VNET --subnet $SUBNET         --nsg $NSG --availability-set $AVSET --public-ip-address ""         --admin-username azureuser --generate-ssh-keys         --custom-data <(echo '#cloud-config\npackage_update: true\npackages:\n  - nginx\nruncmd:\n  - echo "Hola desde '${VM^^}'" > /var/www/html/index.html\n  - systemctl enable --now nginx')         -o none

  echo "⏳ Esperando NIC de $VM..."
  while true; do
    NIC_NAME=$(az vm nic list -g $RG --vm-name $VM --query "[0].name" -o tsv 2>/dev/null)
    if [[ -n "$NIC_NAME" ]]; then
      break
    fi
    sleep 5
  done

  IPCFG=$(az network nic show -g $RG -n $NIC_NAME --query "ipConfigurations[0].name" -o tsv)
  echo "🔁 Asociando $NIC_NAME ($IPCFG) al backend pool..."
  az network nic ip-config address-pool add -g $RG --nic-name "$NIC_NAME" --ip-config-name "$IPCFG"         --lb-name $LB --address-pool $BACKEND -o none
done

IP=$(az network public-ip show -g $RG -n pip-nlb --query ipAddress -o tsv)
echo "✅ Laboratorio listo: http://$IP"
