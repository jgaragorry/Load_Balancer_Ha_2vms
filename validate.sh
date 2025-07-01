#!/usr/bin/env bash
# Validate deployment health and cost guard‑rails.
set -euo pipefail
RG="${1:-demo-halbrg}"
LB_PIP=$(az network public-ip list -g "$RG" --query "[0].ipAddress" -o tsv)

printf "➡️  Checking HTTP response...\n"
if curl -fs "http://$LB_PIP" >/dev/null; then
  echo "✅ Web tier is reachable (200 OK) at http://$LB_PIP"
else
  echo "❌ Web tier failed health check" >&2
  exit 1
fi

printf "➡️  Verifying VM sizes & state...\n"
VM_SIZES=$(az vm list -g "$RG" --show-details --query "[].{name:name,size:hardwareProfile.vmSize,power:powerState}" -o tsv)
echo "$VM_SIZES" | while read -r name size power; do
  [[ "$size" == "Standard_B1s" ]] || { echo "❌ $name size is $size (expected B1s)"; exit 1; }
  [[ "$power" == "VM running" ]] || { echo "❌ $name not running"; exit 1; }
  echo "✅ $name passes.";
done

echo "All sanity checks passed."
