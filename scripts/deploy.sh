#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/terraform/environments/dev"
K8S_DIR="${ROOT_DIR}/kubernetes/overlays/dev"
APP_DIR="${ROOT_DIR}/apps/cloud-cost-advisor"
APP_NAME="cloud-cost-advisor"

: "${BUDGET_ALERT_EMAIL:?Set BUDGET_ALERT_EMAIL}"
: "${APP_DOMAIN:?Set APP_DOMAIN}"
: "${TF_BACKEND_RESOURCE_GROUP:?Set TF_BACKEND_RESOURCE_GROUP}"
: "${TF_BACKEND_STORAGE_ACCOUNT:?Set TF_BACKEND_STORAGE_ACCOUNT}"
: "${TF_BACKEND_CONTAINER:?Set TF_BACKEND_CONTAINER}"

cd "${TF_DIR}"
terraform init -reconfigure \
  -backend-config="resource_group_name=${TF_BACKEND_RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${TF_BACKEND_STORAGE_ACCOUNT}" \
  -backend-config="container_name=${TF_BACKEND_CONTAINER}" \
  -backend-config="key=dev.tfstate"

terraform apply -auto-approve -var="budget_alert_email=${BUDGET_ALERT_EMAIL}"

RG_NAME="$(terraform output -raw resource_group_name)"
AKS_NAME="$(terraform output -raw aks_cluster_name)"
ACR_NAME="$(terraform output -raw acr_name)"

az aks get-credentials --resource-group "${RG_NAME}" --name "${AKS_NAME}" --overwrite-existing
az acr login --name "${ACR_NAME}"

IMAGE_TAG="$(date +%Y%m%d%H%M%S)"
docker build -t "${ACR_NAME}.azurecr.io/${APP_NAME}:${IMAGE_TAG}" "${APP_DIR}"
docker push "${ACR_NAME}.azurecr.io/${APP_NAME}:${IMAGE_TAG}"

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --set controller.replicaCount=1

kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --set crds.enabled=true

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f "${K8S_DIR}/kube-prometheus-stack-values.yaml"

kubectl apply -k "${K8S_DIR}"
kubectl -n dev set image deployment/${APP_NAME} app="${ACR_NAME}.azurecr.io/${APP_NAME}:${IMAGE_TAG}"
kubectl patch clusterissuer letsencrypt-staging --type merge -p "{\"spec\":{\"acme\":{\"email\":\"${BUDGET_ALERT_EMAIL}\"}}}"
kubectl -n dev patch ingress ${APP_NAME} --type json -p "[{\"op\":\"replace\",\"path\":\"/spec/rules/0/host\",\"value\":\"${APP_DOMAIN}\"},{\"op\":\"replace\",\"path\":\"/spec/tls/0/hosts/0\",\"value\":\"${APP_DOMAIN}\"}]"

kubectl rollout status deployment/${APP_NAME} -n dev --timeout=240s

kubectl get pods -n dev
kubectl get ingress -n dev
kubectl get pods -n monitoring

echo "Deploy completed."
