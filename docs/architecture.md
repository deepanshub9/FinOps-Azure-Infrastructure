# Architecture (Learning, Budget-Aware)

## Core Components

- Azure Resource Group
- Virtual Network + AKS subnet
- AKS cluster (single small system node pool)
- Azure Container Registry (Basic)
- Azure Key Vault
- Log Analytics Workspace
- Azure Monitor Action Group + Resource Group Budget Alert

## Kubernetes Layer

- `Namespace` with restricted pod security labels
- `NetworkPolicy` default deny
- `ServiceAccount` + Role/RoleBinding
- `Deployment`, `Service`, `Ingress`, `HPA`, `PDB` for `cloud-cost-advisor`
- `ClusterIssuer` for cert-manager (Let's Encrypt staging)
- `ServiceMonitor` and `PrometheusRule` for application metrics and alerting

## Application Layer

- Python FastAPI service under `apps/cloud-cost-advisor`
- Endpoints:
  - `GET /api/v1/workloads`
  - `POST /api/v1/workloads`
  - `PATCH /api/v1/workloads/{id}`
  - `DELETE /api/v1/workloads/{id}`
  - `GET /api/v1/insights`
  - `GET /api/v1/health`, `GET /readyz`, `GET /metrics`

## Observability Layer

- `kube-prometheus-stack` (Prometheus, Grafana, Alertmanager)
- App-level metric scraping via ServiceMonitor
- App-specific alert rules via PrometheusRule
- Azure Monitor diagnostics + Log Analytics for AKS control-plane visibility

## Delivery

- Azure DevOps `deploy.yml`: validate -> provision -> deploy -> smoke check
- Azure DevOps `destroy.yml`: confirmed teardown
- Local scripts for equivalent one-click flow

## Rollback Model

- Rolling update strategy in Deployment
- Automatic rollback stage in pipeline on deployment stage failure
- Manual rollback via `kubectl rollout undo deployment/cloud-cost-advisor -n dev`
