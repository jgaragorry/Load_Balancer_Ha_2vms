#!/bin/bash

RG="rg-nlb-lab"

echo "🌐 Verificando IP pública del Load Balancer..."
IP=$(az network public-ip show -g $RG -n pip-nlb --query ipAddress -o tsv)
echo "✅ IP Pública: $IP"

echo "🔁 Probando balanceo con curl (x5)..."
for i in {1..5}; do
  echo "Intento $i:"
  curl -s http://$IP
  echo ""
done
