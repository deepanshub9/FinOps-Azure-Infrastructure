import importlib
from datetime import datetime
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from pydantic import ValidationError

from .database import get_connection, init_db
from .schemas import InsightsResponse, Workload, WorkloadCreate, WorkloadUpdate
from .service import calculate_insights

app = FastAPI(title="Cloud Cost Advisor", version="1.0.0")
BASE_DIR = Path(__file__).resolve().parents[1]
Instrumentator = importlib.import_module("prometheus_fastapi_instrumentator").Instrumentator


@app.on_event("startup")
def startup_event() -> None:
    init_db()


def row_to_workload(row: dict) -> Workload:
    return Workload(
        id=row["id"],
        name=row["name"],
        owner_team=row["owner_team"],
        provider=row["provider"],
        monthly_cost_usd=row["monthly_cost_usd"],
        cpu_utilization_pct=row["cpu_utilization_pct"],
        memory_utilization_pct=row["memory_utilization_pct"],
        criticality=row["criticality"],
        auto_shutdown_enabled=bool(row["auto_shutdown_enabled"]),
        created_at=datetime.fromisoformat(row["created_at"]),
        updated_at=datetime.fromisoformat(row["updated_at"]),
    )


@app.get("/api/v1/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/readyz")
def readyz() -> dict[str, str]:
    return {"status": "ready"}


@app.get("/api/v1/workloads", response_model=list[Workload])
def list_workloads() -> list[Workload]:
    with get_connection() as conn:
        rows = conn.execute("SELECT * FROM workloads ORDER BY monthly_cost_usd DESC, id DESC").fetchall()
    return [row_to_workload(dict(row)) for row in rows]


@app.post("/api/v1/workloads", response_model=Workload, status_code=201)
def create_workload(payload: WorkloadCreate) -> Workload:
    with get_connection() as conn:
        cursor = conn.execute(
            """
            INSERT INTO workloads (
              name, owner_team, provider, monthly_cost_usd,
              cpu_utilization_pct, memory_utilization_pct,
              criticality, auto_shutdown_enabled
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                payload.name,
                payload.owner_team,
                payload.provider,
                payload.monthly_cost_usd,
                payload.cpu_utilization_pct,
                payload.memory_utilization_pct,
                payload.criticality,
                int(payload.auto_shutdown_enabled),
            ),
        )
        row = conn.execute("SELECT * FROM workloads WHERE id = ?", (cursor.lastrowid,)).fetchone()

    return row_to_workload(dict(row))


@app.patch("/api/v1/workloads/{workload_id}", response_model=Workload)
def update_workload(workload_id: int, payload: WorkloadUpdate) -> Workload:
    update_values = payload.model_dump(exclude_unset=True)
    if not update_values:
        raise HTTPException(status_code=400, detail="No fields provided for update")

    with get_connection() as conn:
        existing = conn.execute("SELECT * FROM workloads WHERE id = ?", (workload_id,)).fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="Workload not found")

        merged = {**dict(existing), **update_values}
        merged["auto_shutdown_enabled"] = int(merged["auto_shutdown_enabled"])

        try:
            WorkloadCreate(
                name=merged["name"],
                owner_team=merged["owner_team"],
                provider=merged["provider"],
                monthly_cost_usd=merged["monthly_cost_usd"],
                cpu_utilization_pct=merged["cpu_utilization_pct"],
                memory_utilization_pct=merged["memory_utilization_pct"],
                criticality=merged["criticality"],
                auto_shutdown_enabled=bool(merged["auto_shutdown_enabled"]),
            )
        except ValidationError as exc:
            raise HTTPException(status_code=422, detail=exc.errors()) from exc

        conn.execute(
            """
            UPDATE workloads
            SET name = ?, owner_team = ?, provider = ?, monthly_cost_usd = ?,
                cpu_utilization_pct = ?, memory_utilization_pct = ?,
                criticality = ?, auto_shutdown_enabled = ?
            WHERE id = ?
            """,
            (
                merged["name"],
                merged["owner_team"],
                merged["provider"],
                merged["monthly_cost_usd"],
                merged["cpu_utilization_pct"],
                merged["memory_utilization_pct"],
                merged["criticality"],
                merged["auto_shutdown_enabled"],
                workload_id,
            ),
        )

        row = conn.execute("SELECT * FROM workloads WHERE id = ?", (workload_id,)).fetchone()

    return row_to_workload(dict(row))


@app.delete("/api/v1/workloads/{workload_id}", status_code=204)
def delete_workload(workload_id: int) -> None:
    with get_connection() as conn:
        deleted = conn.execute("DELETE FROM workloads WHERE id = ?", (workload_id,)).rowcount
        if deleted == 0:
            raise HTTPException(status_code=404, detail="Workload not found")


@app.get("/api/v1/insights", response_model=InsightsResponse)
def insights() -> InsightsResponse:
    workloads = list_workloads()
    return calculate_insights(workloads)


Instrumentator(should_group_status_codes=True, should_ignore_untemplated=True).instrument(app).expose(
    app,
    endpoint="/metrics",
    include_in_schema=False,
)


app.mount("/", StaticFiles(directory=str(BASE_DIR / "static"), html=True), name="static")
