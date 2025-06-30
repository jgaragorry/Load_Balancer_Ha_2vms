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
VM1="vm1"
VM2="vm2"

echo "🔐 Iniciando sesión..."
az login

echo "🔧 Creando grupo de recursos..."
az group create --name $RG --location $LOCATION --tags autor=gmtech proyecto=lab_nlb_ha

echo "🌐 Creando VNet y subred..."
az network vnet create --name $VNET --resource-group $RG --location $LOCATION --address-prefixes 10.20.0.0/16 --subnet-name $SUBNET --subnet-prefixes 10.20.1.0/24

echo "🧱 Creando Availability Set..."
az vm availability-set create --name $AVSET --resource-group $RG --location $LOCATION --platform-fault-domain-count 2 --platform-update-domain-count 2

echo "🔒 Creando NSG con reglas..."
az network nsg create --resource-group $RG --name $NSG --location $LOCATION
az network nsg rule create --resource-group $RG --nsg-name $NSG --name Allow80 --protocol Tcp --direction Inbound --priority 1000 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 80 --access Allow

echo "🌐 Creando IP pública..."
az network public-ip create --name pip-nlb --resource-group $RG --location $LOCATION --sku Basic --allocation-method Static

echo "🧱 Creando Load Balancer..."
az network lb create --resource-group $RG --name $LB --sku Basic --frontend-ip-name $FRONT --backend-pool-name $BACKEND --public-ip-address pip-nlb --location $LOCATION

echo "📡 Agregando probe para salud HTTP..."
az network lb probe create --resource-group $RG --lb-name $LB --name $PROBE --protocol Http --port 80 --path "/" --interval 15 --threshold 2

echo "⚙️ Configurando regla de balanceo (HTTP 80)..."
az network lb rule create --resource-group $RG --lb-name $LB --name $RULE --protocol Tcp --frontend-port 80 --backend-port 80 --frontend-ip-name $FRONT --backend-pool-name $BACKEND --probe-name $PROBE

echo "🖥️ Creando VM1..."
az vm create --resource-group $RG --name $VM1 --image Ubuntu2204 --vnet-name $VNET --subnet $SUBNET --nsg $NSG --availability-set $AVSET --public-ip-address "" --admin-username azureuser --generate-ssh-keys --custom-data cloud-init-vm1.yml

echo "🖥️ Creando VM2..."
az vm create --resource-group $RG --name $VM2 --image Ubuntu2204 --vnet-name $VNET --subnet $SUBNET --nsg $NSG --availability-set $AVSET --public-ip-address "" --admin-username azureuser --generate-ssh-keys --custom-data cloud-init-vm2.yml

echo "⏳ Esperando a que las VMs estén listas..."
sleep 30

echo "🔁 Agregando NIC de VM1 al backend del LB..."
NIC_ID1=$(az vm show --resource-group $RG --name $VM1 --query "networkProfile.networkInterfaces[0].id" -o tsv)
NIC_NAME1=$(basename $NIC_ID1)
az network nic ip-config address-pool add --resource-group $RG --nic-name $NIC_NAME1 --ip-config-name ipconfig1 --lb-name $LB --address-pool $BACKEND

echo "🔁 Agregando NIC de VM2 al backend del LB..."
NIC_ID2=$(az vm show --resource-group $RG --name $VM2 --query "networkProfile.networkInterfaces[0].id" -o tsv)
NIC_NAME2=$(basename $NIC_ID2)
az network nic ip-config address-pool add --resource-group $RG --nic-name $NIC_NAME2 --ip-config-name ipconfig1 --lb-name $LB --address-pool $BACKEND

echo "✅ Laboratorio creado correctamente."
IP=$(az network public-ip show --resource-group $RG --name pip-nlb --query ipAddress -o tsv)
echo "🌐 Accede al balanceador en: http://$IP"
