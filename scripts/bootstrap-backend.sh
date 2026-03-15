#!/usr/bin/env bash
set -euo pipefail

: "${TF_STATE_LOCATION:=francecentral}"
: "${TF_BACKEND_RESOURCE_GROUP:?Set TF_BACKEND_RESOURCE_GROUP}"
: "${TF_BACKEND_STORAGE_ACCOUNT:?Set TF_BACKEND_STORAGE_ACCOUNT}"
: "${TF_BACKEND_CONTAINER:?Set TF_BACKEND_CONTAINER}"

az group create --name "${TF_BACKEND_RESOURCE_GROUP}" --location "${TF_STATE_LOCATION}" >/dev/null

az storage account create \
  --name "${TF_BACKEND_STORAGE_ACCOUNT}" \
  --resource-group "${TF_BACKEND_RESOURCE_GROUP}" \
  --location "${TF_STATE_LOCATION}" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false >/dev/null

ACCOUNT_KEY="$(az storage account keys list \
  --account-name "${TF_BACKEND_STORAGE_ACCOUNT}" \
  --resource-group "${TF_BACKEND_RESOURCE_GROUP}" \
  --query "[0].value" -o tsv)"

az storage container create \
  --name "${TF_BACKEND_CONTAINER}" \
  --account-name "${TF_BACKEND_STORAGE_ACCOUNT}" \
  --account-key "${ACCOUNT_KEY}" >/dev/null

echo "Terraform backend created."
