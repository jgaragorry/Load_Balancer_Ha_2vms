#!/bin/bash
set -e

RG="rg-nlb-lab"
LOC="eastus"
VNET="vnet-nlb"
SUBNET="subnet-nlb"
VM_SIZE="Standard_B1s"
USERNAME="azureuser"
PASSWORD="Password1234"
AVSET="avset-nlb"
NSG="nsg-nlb"
PUBLIC_IP="pip-nlb"
LB_NAME="lb-nlb"
LB_FRONT="lb-front"
LB_BACKEND="lb-backend"
PROBE="http-probe"
RULE="lb-rule-http"
TAGS="autor=gmtech proyecto=lab_nlb_ha"

echo "🔐 Iniciando sesión..."
az login

echo "🔧 Creando grupo de recursos..."
az group create -n $RG -l $LOC --tags $TAGS

echo "🌐 Creando VNet y subred..."
az network vnet create -g $RG -n $VNET --address-prefix 10.20.0.0/16   --subnet-name $SUBNET --subnet-prefix 10.20.1.0/24

echo "🧱 Creando Availability Set..."
az vm availability-set create -n $AVSET -g $RG   --platform-fault-domain-count 2 --platform-update-domain-count 2

echo "🔒 Creando NSG con reglas..."
az network nsg create -g $RG -n $NSG
az network nsg rule create -g $RG --nsg-name $NSG -n Allow80 --priority 1000   --access Allow --protocol Tcp --direction Inbound --destination-port-range 80

echo "🌐 Creando IP pública..."
az network public-ip create -g $RG -n $PUBLIC_IP --sku Basic --allocation-method Static

echo "🧱 Creando Load Balancer..."
az network lb create -g $RG -n $LB_NAME --sku Basic   --public-ip-address $PUBLIC_IP   --frontend-ip-name $LB_FRONT   --backend-pool-name $LB_BACKEND

echo "📡 Agregando probe para salud HTTP..."
az network lb probe create -g $RG --lb-name $LB_NAME -n $PROBE   --protocol Http --port 80 --path /

echo "⚙️ Configurando regla de balanceo (HTTP 80)..."
az network lb rule create -g $RG --lb-name $LB_NAME -n $RULE   --backend-pool-name $LB_BACKEND --backend-port 80   --frontend-ip-name $LB_FRONT --frontend-port 80   --protocol Tcp --probe-name $PROBE

for i in 1 2; do
  echo "🖥️ Creando VM$i..."
  az vm create     --resource-group $RG     --name vm$i-nlb     --image Ubuntu2204     --size $VM_SIZE     --admin-username $USERNAME     --admin-password $PASSWORD     --vnet-name $VNET     --subnet $SUBNET     --nsg $NSG     --availability-set $AVSET     --tags $TAGS     --no-wait
done

echo "⏳ Esperando a que las VMs estén listas..."
sleep 90

for i in 1 2; do
  echo "🔁 Agregando NIC de VM$i al backend del LB..."
  NIC_ID=$(az vm show -g $RG -n vm$i-nlb --query 'networkProfile.networkInterfaces[0].id' -o tsv)
  NIC_NAME=$(basename $NIC_ID)

  az network nic ip-config address-pool add     --address-pool $LB_BACKEND     --ip-config-name ipconfig1     --nic-name $NIC_NAME     --resource-group $RG     --lb-name $LB_NAME     --backend-pool-name $LB_BACKEND

  echo "📝 Instalando Nginx y contenido en VM$i..."
  az vm run-command invoke -g $RG -n vm$i-nlb     --command-id RunShellScript     --scripts "sudo mkdir -p /var/www/html && echo 'Hola desde VM$i' | sudo tee /var/www/html/index.html && sudo apt update && sudo apt install -y nginx && sudo systemctl start nginx"
done

IP_PUBLICA=$(az network public-ip show -g $RG -n $PUBLIC_IP --query ipAddress -o tsv)
echo "✅ Laboratorio creado correctamente."
echo "🌐 Accede al balanceador en: http://$IP_PUBLICA"
