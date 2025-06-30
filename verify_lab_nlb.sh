#!/bin/bash
set -e

RG="rg-nlb-lab"
PUBLIC_IP_NAME="pip-nlb"
LB_NAME="lb-nlb"

echo "🌐 Verificando IP pública del Load Balancer..."
IP=$(az network public-ip show -g $RG -n $PUBLIC_IP_NAME --query ipAddress -o tsv)
echo "✅ IP Pública: $IP"

echo "🔁 Probando balanceo con curl (x5)..."
for i in {1..5}; do
  echo -n "Intento $i: "
  curl -s http://$IP | grep Hola || echo "⚠️ Respuesta inesperada"
  sleep 1
done

echo "📊 Estado del Load Balancer y VMs:"
az network lb show -g $RG -n $LB_NAME --query "{name:name, sku:sku.name, state:provisioningState}" -o table
az vm list -g $RG --show-details --query "[].{VM:name, Estado:powerState}" -o table
