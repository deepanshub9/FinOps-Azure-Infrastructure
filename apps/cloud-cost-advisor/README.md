# Cloud Cost Advisor

A small real-world app to help teams track workload spend and identify cloud cost optimization opportunities.

## Features

- Add and manage workload records (team, provider, cost, utilization, criticality).
- Compute actionable optimization recommendations and estimated savings.
- Interactive dashboard UI for quick analysis.

## Run locally

```bash
cd apps/cloud-cost-advisor
python -m pip install -r requirements.txt
python -m uvicorn src.main:app --host 127.0.0.1 --port 8080
```

Open `http://127.0.0.1:8080`.

## API endpoints

- `GET /api/v1/health`
- `GET /readyz`
- `GET /api/v1/workloads`
- `POST /api/v1/workloads`
- `PATCH /api/v1/workloads/{id}`
- `DELETE /api/v1/workloads/{id}`
- `GET /api/v1/insights`
- `GET /metrics`
