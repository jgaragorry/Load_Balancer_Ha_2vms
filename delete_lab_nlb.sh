#!/bin/bash
RG="rg-nlb-lab"
echo "⚠️ Eliminando el grupo $RG..."
az group delete -n $RG --yes --no-wait
