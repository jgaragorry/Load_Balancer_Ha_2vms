#!/usr/bin/env bash
# Destroy all resources created by deploy.sh.
# Usage:
#   ./destroy.sh                # delete default RG (demo-halbrg) with interactive prompt
#   ./destroy.sh myRG           # delete specific RG with interactive prompt
#   ./destroy.sh --force        # delete default RG non‑interactive
#   ./destroy.sh myRG --force   # delete specific RG non‑interactive

set -euo pipefail

DEFAULT_RG="demo-halbrg"
RG="$DEFAULT_RG"
FORCE=false

# ------------
# Parse args
# ------------
for arg in "$@"; do
  case "$arg" in
    --force)
      FORCE=true
      ;;
    -g|--resource-group)
      # next argument is RG name
      shift
      RG="$1"
      ;;
    *)
      RG="$arg"
      ;;
  esac
  shift || true
done

# -------------
# Confirmation
# -------------
if ! $FORCE; then
  read -rp "Are you sure you want to delete resource group $RG? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

# -------------
# Delete RG
# -------------
echo "Initiating delete of $RG..."
if ! az group exists --name "$RG" | grep -q true; then
  echo "Resource group $RG does not exist or already deleted.";
  exit 0;
fi

az group delete --name "$RG" --yes --no-wait

printf "Waiting for RG to be purged";
while az group exists --name "$RG" | grep -q true; do
  printf "."; sleep 10;
done

echo -e "
✅ Resource group $RG deleted. Cleanup complete."
