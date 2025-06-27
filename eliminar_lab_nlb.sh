#!/bin/bash

RG="rg-nlb-lab"

echo "⚠️ ¡Eliminarás todos los recursos del laboratorio NLB!"
echo "⏳ Si lo usaste menos de 1h, el costo estimado es menor a $0.10 USD"
echo "¿Continuar? (s/n): "
read confirm

if [[ "$confirm" != "s" ]]; then
  echo "❌ Operación cancelada."
  exit 1
fi

az group delete -n $RG --yes --no-wait

while az group exists -n $RG; do
  echo "⏳ Esperando que se elimine el grupo de recursos..."
  sleep 10
done

echo "✅ Laboratorio eliminado."