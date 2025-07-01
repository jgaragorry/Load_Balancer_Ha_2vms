#!/bin/bash
RG="rg-nlb-lab"
IP=$(az network public-ip show -g $RG -n pip-nlb --query ipAddress -o tsv)
echo "IP pública: $IP"
for i in {1..6}; do
  echo -n "Intento $i: "
  curl --max-time 5 -s http://$IP || echo "falló"
  echo
done
