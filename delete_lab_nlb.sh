#!/bin/bash

RG="rg-nlb-lab"

echo "⚠️ Eliminando todos los recursos del laboratorio NLB..."
az group delete --name $RG --yes --no-wait

while az group exists -n $RG; do
  echo "⏳ Esperando que se elimine el grupo de recursos..."
  sleep 10
done

echo "✅ Laboratorio eliminado."
