# ☁️ Cloud Cost Advisor — AKS Learning Project

> A production-style learning project built on Azure Kubernetes Service.
> Deploy a real application, observe it, and tear it all down — without breaking the bank.

---

## 👋 What Is This?

This project is a hands-on learning environment that mirrors how real engineering teams build and operate cloud infrastructure. It is not a toy — it uses the same tools, patterns, and practices you would find in a professional engineering team.

At the centre of it is **Cloud Cost Advisor**, a web application that helps teams track their cloud workload spending and act on cost optimisation opportunities. The application runs inside a Kubernetes cluster on Azure, is monitored with Prometheus and Grafana, and is deployed through automated scripts and CI/CD pipelines.

If you are learning DevOps, cloud engineering, or Kubernetes — this project gives you a real environment to practice in.

---

## 💡 What Will You Learn?

By working through this project you will get hands-on experience with:

- Provisioning real Azure infrastructure using **Terraform**
- Running containerised workloads on **Azure Kubernetes Service (AKS)**
- Building and pushing Docker images to **Azure Container Registry (ACR)**
- Setting up monitoring and alerting with **Prometheus, Grafana, and Alertmanager**
- Managing TLS certificates automatically with **cert-manager and Let's Encrypt**
- Deploying and destroying everything with a single script
- Running CI/CD pipelines with **Azure DevOps**

---

## 🏗️ What Gets Built

When you run the deploy script, here is everything that gets created in Azure:

**Infrastructure (via Terraform)**

- A dedicated Resource Group to hold all resources
- A Virtual Network and subnet for the AKS cluster
- An AKS cluster running a single node (kept small to save cost)
- An Azure Container Registry to store your Docker images
- An Azure Key Vault for secrets management
- A Log Analytics Workspace for AKS control plane logs
- A budget alert set at $15/month so you never get a surprise bill

**Kubernetes Platform (via Helm and Kustomize)**

- Ingress controller to route traffic into the cluster
- cert-manager for automatic HTTPS certificates
- Prometheus, Grafana, and Alertmanager for full observability
- Network policies, pod security, RBAC, and service accounts
- Horizontal Pod Autoscaler and Pod Disruption Budget for the application

---

## 🧠 The Application — Cloud Cost Advisor

Cloud Cost Advisor is a FastAPI web application with a browser-based dashboard. It gives engineering teams visibility into their cloud workload spending and surfaces actionable recommendations.

**What it does:**

- Tracks workloads across providers with cost, CPU utilisation, memory utilisation, and criticality data
- Calculates total monthly spend and average resource utilisation across all workloads
- Identifies workloads that are over-provisioned and wasting money
- Recommends rightsizing, auto-shutdown for non-critical workloads, and Azure Savings Plan opportunities
- Estimates how much money each recommendation could save per month
- Exposes a Prometheus metrics endpoint so Grafana can graph everything in real time
- Provides health and readiness endpoints for Kubernetes to manage the pod lifecycle

**The recommendation engine looks for three patterns:**

- Workloads where average CPU and memory utilisation is below 25% — these are candidates for rightsizing
- Non-critical workloads without auto-shutdown enabled — enabling off-hours shutdown saves roughly 15% per month
- Azure workloads with utilisation below 45% — these are good candidates for Reserved Instances or Savings Plans

---

## 📁 Project Structure

```
.
├── apps/
│   └── cloud-cost-advisor/     The FastAPI application
├── terraform/
│   ├── environments/dev/       Environment-level Terraform config
│   └── modules/                Reusable modules for AKS, network, observability
├── kubernetes/
│   ├── base/                   Core Kubernetes manifests
│   └── overlays/dev/           Dev-specific patches and values
├── pipelines/azure-devops/     CI/CD pipeline definitions
├── scripts/                    One-click deploy and destroy scripts
└── docs/                       Architecture notes and runbooks
```

---

## 🔧 Prerequisites

Before you start, make sure you have these tools installed on your machine:

| Tool | Purpose |
|---|---|
| Azure CLI | Authenticate and manage Azure resources |
| Terraform | Provision infrastructure |
| kubectl | Manage Kubernetes workloads |
| Helm | Install Kubernetes packages |
| Docker | Build and push container images |
| Git Bash or WSL | Run shell scripts on Windows |

You will also need an active Azure subscription. An Azure for Students subscription works, but note that it restricts deployments to specific regions only.

---

## ⚙️ How Deployment Works

The deployment is split into three scripts, each with a clear purpose:

**bootstrap-backend.sh — Run once, ever**

This creates an Azure Storage Account to store the Terraform state file remotely. The state file is how Terraform remembers what it has already created. Running this once means your state is safely stored in Azure rather than only on your laptop.

**deploy.sh — Run when you want to practice**

This is the main script. It does three things in sequence. First it runs Terraform to provision all the Azure infrastructure. Then it builds your Docker image and pushes it to ACR. Finally it applies all the Kubernetes manifests to get the application and monitoring stack running in the cluster.

**destroy.sh — Run when you are done**

This tears everything down cleanly. It runs Terraform destroy to remove all Azure resources and cleans up the Kubernetes state. Always run this after a learning session to avoid unnecessary costs.

---

## 📊 Monitoring and Observability

The project ships with a full observability stack out of the box.

**Prometheus** scrapes metrics from the application every 15 seconds via a ServiceMonitor. The application exposes HTTP request counts, latency histograms, and error rates through its metrics endpoint.

**Grafana** visualises everything. The recommended dashboards for this project are:

- Node Exporter Full (ID 1860) — node CPU, memory, disk, and network
- Kubernetes Cluster (ID 6417) — pod health, restarts, and resource usage
- FastAPI Observability (ID 16110) — application request rate, latency, and errors

**Alertmanager** handles notifications. Two alert rules are pre-configured:

- Fires when the API 5xx error rate exceeds 0.1 requests per second for 5 minutes
- Fires when pod restarts exceed 3 in a 15-minute window

**Azure Monitor** captures AKS control plane logs including the API server, controller manager, and scheduler. These are queryable in Log Analytics using KQL.

---

## 💰 Cost and Budget Awareness

This project is designed for ephemeral use. AKS is not cost-effective as an always-on environment on a student or personal subscription.

The recommended pattern is:

- Deploy when you sit down to practice
- Work through what you want to learn
- Destroy when you are done

A budget alert is configured at $15/month with notifications at 80% actual spend and 100% forecasted spend. You will receive an email before costs get out of hand.

The biggest cost drivers to watch are:

- The AKS node VM running continuously
- The public load balancer
- Log Analytics data ingestion if the environment stays up for days

---

## 🔄 CI/CD with Azure DevOps

Two pipelines are included under `pipelines/azure-devops/`:

**deploy.yml** runs through four stages — validate the Terraform plan, provision the infrastructure, build and deploy the application, and run a smoke check to confirm the app is responding.

**destroy.yml** provides a confirmed teardown pipeline with a manual approval gate so you never accidentally destroy a running environment.

The pipelines require these variables to be set in your Azure DevOps project:

- `AZURE_SERVICE_CONNECTION` — your Azure service connection name
- `TF_BACKEND_RESOURCE_GROUP` — resource group holding the Terraform state storage
- `TF_BACKEND_STORAGE_ACCOUNT` — storage account name for Terraform state
- `TF_BACKEND_CONTAINER` — blob container name
- `BUDGET_ALERT_EMAIL` — email address for budget and alert notifications
- `APP_DOMAIN` — the domain name for your application ingress

---

## 🔐 Security Practices

This project follows security best practices throughout:

- The application container runs as a non-root user
- The Kubernetes namespace enforces restricted pod security policy
- All pod capabilities are dropped with only the minimum required
- The root filesystem is read-only inside the container
- Network policies default-deny all traffic and only allow what is explicitly needed
- AKS pulls images from ACR using a managed identity with the AcrPull role — no passwords involved
- Key Vault is provisioned and ready for secrets if you extend the project

---

## 🗺️ Architecture at a Glance

```
Internet
    │
    ▼
Azure Load Balancer (Public IP)
    │
    ▼
ingress-nginx (Kubernetes)
    │
    ▼
cloud-cost-advisor (FastAPI Pod)
    │
    ├── SQLite database (ephemeral volume)
    ├── /metrics → Prometheus scrapes here
    └── /api/v1/ → REST API endpoints

Prometheus → Grafana (dashboards + alerts)
           → Alertmanager → Email notifications

AKS Control Plane → Log Analytics → Azure Monitor
```

---

## 🤝 Who Is This For?

This project is for anyone who wants to learn cloud and Kubernetes by doing rather than reading. It is particularly useful if you are:

- A developer moving into DevOps or platform engineering
- A student working through cloud certifications
- Someone who wants a realistic project for their portfolio
- A learner who wants to understand how monitoring, security, and CI/CD fit together in a real system

---

## ⚠️ Important Notes

- Always destroy the environment after each session to avoid unexpected costs
- The Terraform state file contains sensitive resource IDs — do not commit it to a public repository
- The Grafana admin password in the values file should be changed before any shared use
- Let's Encrypt staging certificates are used by default — they are not trusted by browsers but are free and safe for learning
- If you are on an Azure for Students subscription, you can only deploy to these regions: `francecentral`, `germanywestcentral`, `norwayeast`, `spaincentral`, `switzerlandnorth`

---

> Built for learning. Designed like production. Destroyed after practice. 🚀
