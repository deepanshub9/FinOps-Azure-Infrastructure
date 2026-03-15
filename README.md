# Real Usecase - AKS + Terraform + Kubernetes + Azure DevOps

Production-style learning project with strict cost guardrails.

## Goals

- One-click deploy and one-click destroy.
- Terraform for Azure infrastructure.
- Kubernetes YAML for workloads and platform objects.
- Monitoring, observability, alerting, rollback-ready deployment path.
- Budget-aware operation for learning.

## Repository Structure

- `apps/cloud-cost-advisor/` Interactive FastAPI dashboard for workload cost tracking and optimization insights.
- `terraform/` Infrastructure modules and environment stacks.
- `kubernetes/` Platform, workload, and observability manifests.
- `pipelines/azure-devops/` CI/CD YAML for deploy and destroy.
- `scripts/` Local one-click scripts.
- `docs/` Architecture and runbooks.

## Application (Real Use Case)

`cloud-cost-advisor` helps teams track workload spend and act on optimization opportunities:

- Interactive web dashboard for browser-based access.
- Workload inventory with provider, cost, utilization, and criticality data.
- Recommendation engine for rightsizing, auto-shutdown, and Azure savings plan opportunities.
- Health/readiness and Prometheus `/metrics` endpoints for Kubernetes operations.

## Quick Start (Local)

1. Prerequisites: `az`, `terraform`, `kubectl`, `helm`, `docker`.
2. Login:
   ```bash
   az login
   az account set --subscription "<your-subscription-id>"
   ```
3. Set variables:
   ```bash
   export BUDGET_ALERT_EMAIL="you@example.com"
   export APP_DOMAIN="app.yourdomain.com"
   export TF_BACKEND_RESOURCE_GROUP="rg-tfstate-shared"
   export TF_BACKEND_STORAGE_ACCOUNT="tfstateacct12345"
   export TF_BACKEND_CONTAINER="tfstate"
   ```
4. Create backend once:
   ```bash
   ./scripts/bootstrap-backend.sh
   ```
5. Deploy:
   ```bash
   ./scripts/deploy.sh
   ```
6. Destroy:
   ```bash
   ./scripts/destroy.sh --yes
   ```

## Azure DevOps Variables Required

Set these pipeline variables or variable-group values:

- `AZURE_SERVICE_CONNECTION`
- `TF_BACKEND_RESOURCE_GROUP`
- `TF_BACKEND_STORAGE_ACCOUNT`
- `TF_BACKEND_CONTAINER`
- `BUDGET_ALERT_EMAIL`
- `APP_DOMAIN`

## Budget Note

AKS is not realistic as always-on under $15/month. This project is designed for ephemeral learning cycles: deploy only when practicing and destroy after.

## Monitoring Stack Included

- Prometheus + Alertmanager + Grafana (`kube-prometheus-stack` Helm chart).
- ServiceMonitor + PrometheusRule for Cloud Cost Advisor.
- Azure Monitor via AKS diagnostics to Log Analytics and action group notifications.
