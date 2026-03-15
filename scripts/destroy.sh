#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/terraform/environments/dev"

: "${BUDGET_ALERT_EMAIL:?Set BUDGET_ALERT_EMAIL}"
: "${TF_BACKEND_RESOURCE_GROUP:?Set TF_BACKEND_RESOURCE_GROUP}"
: "${TF_BACKEND_STORAGE_ACCOUNT:?Set TF_BACKEND_STORAGE_ACCOUNT}"
: "${TF_BACKEND_CONTAINER:?Set TF_BACKEND_CONTAINER}"

if [[ "${1:-}" != "--yes" ]]; then
  echo "Refusing to destroy without confirmation flag. Use: ./scripts/destroy.sh --yes"
  exit 1
fi

cd "${TF_DIR}"
terraform init \
  -backend-config="resource_group_name=${TF_BACKEND_RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${TF_BACKEND_STORAGE_ACCOUNT}" \
  -backend-config="container_name=${TF_BACKEND_CONTAINER}" \
  -backend-config="key=dev.tfstate"

RG_NAME="$(terraform output -raw resource_group_name || true)"
AKS_NAME="$(terraform output -raw aks_cluster_name || true)"

if [[ -n "${RG_NAME}" && -n "${AKS_NAME}" ]]; then
  az aks get-credentials --resource-group "${RG_NAME}" --name "${AKS_NAME}" --overwrite-existing || true
  kubectl delete namespace dev --ignore-not-found=true || true
  kubectl delete namespace monitoring --ignore-not-found=true || true
fi

terraform destroy -auto-approve -var="budget_alert_email=${BUDGET_ALERT_EMAIL}"

echo "Destroy completed."
