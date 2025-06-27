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

echo "🔐 Iniciando sesión..."
az login

echo "🔧 Creando grupo de recursos..."
az group create -n $RG -l $LOC --tags autor=gmtech proyecto=lab_nlb_ha

echo "🌐 Creando VNet y subred..."
az network vnet create -g $RG -n $VNET --address-prefix 10.20.0.0/16 \
  --subnet-name $SUBNET --subnet-prefix 10.20.1.0/24

echo "🧱 Creando Availability Set..."
az vm availability-set create -n $AVSET -g $RG --platform-fault-domain-count 2 --platform-update-domain-count 2

echo "🔒 Creando NSG con reglas..."
az network nsg create -g $RG -n nsg-nlb
az network nsg rule create -g $RG --nsg-name nsg-nlb -n Allow80 --priority 1000 \
  --access Allow --protocol Tcp --direction Inbound --destination-port-range 80

echo "🌐 Creando IP pública..."
az network public-ip create -g $RG -n pip-nlb --sku Basic --allocation-method Static

echo "🧱 Creando Load Balancer..."
az network lb create -g $RG -n lb-nlb --sku Basic --public-ip-address pip-nlb \
  --frontend-ip-name lb-front --backend-pool-name lb-backend

echo "⚙️ Configurando regla de balanceo (HTTP 80)..."
az network lb rule create -g $RG --lb-name lb-nlb -n lb-rule-http \
  --backend-pool-name lb-backend --backend-port 80 --frontend-ip-name lb-front \
  --frontend-port 80 --protocol Tcp --probe-name http-probe

echo "📡 Agregando probe para salud HTTP..."
az network lb probe create -g $RG --lb-name lb-nlb -n http-probe \
  --protocol Http --port 80 --path /

for i in 1 2; do
  echo "🖥️ Creando VM$i..."
  az vm create \
    --resource-group $RG \
    --name vm$i-nlb \
    --image Ubuntu2204 \
    --size $VM_SIZE \
    --admin-username $USERNAME \
    --admin-password $PASSWORD \
    --vnet-name $VNET \
    --subnet $SUBNET \
    --nsg nsg-nlb \
    --availability-set $AVSET \
    --no-wait

done

sleep 90

for i in 1 2; do
  echo "🔁 Agregando NIC de VM$i al backend del LB..."
  NIC_ID=$(az vm show -g $RG -n vm$i-nlb --query 'networkProfile.networkInterfaces[0].id' -o tsv)
  az network nic ip-config address-pool add \
    --address-pool lb-backend \
    --ip-config-name ipconfig1 \
    --nic-name $(basename $NIC_ID) \
    --resource-group $RG \
    --lb-name lb-nlb \
    --backend-pool-name lb-backend

  echo "📝 Agregando contenido a VM$i..."
  az vm run-command invoke -g $RG -n vm$i-nlb \
    --command-id RunShellScript \
    --scripts "echo 'Hola desde VM$i' | sudo tee /var/www/html/index.html && sudo apt update && sudo apt install nginx -y && sudo systemctl start nginx"
done

IP_PUBLICA=$(az network public-ip show -g $RG -n pip-nlb --query ipAddress -o tsv)
echo "✅ Laboratorio creado. Accede desde navegador o curl: http://$IP_PUBLICA"