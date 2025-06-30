#!/bin/bash
set -e

RG="rg-nlb-lab"

echo "⚠️ Eliminando el grupo de recursos: $RG..."
az group delete --name $RG --yes --no-wait

echo "⏳ Esperando que el grupo se elimine completamente..."
while az group exists -n $RG | grep true; do
  echo "⏳ Aún existe... esperando 10 segundos"
  sleep 10
done

echo "✅ Grupo eliminado completamente."
