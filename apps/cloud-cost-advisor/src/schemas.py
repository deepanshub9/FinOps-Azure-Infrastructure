from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

Provider = Literal["azure", "aws", "gcp", "onprem"]
Criticality = Literal["low", "medium", "high"]


class WorkloadCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=120)
    owner_team: str = Field(..., min_length=2, max_length=80)
    provider: Provider
    monthly_cost_usd: float = Field(..., ge=0)
    cpu_utilization_pct: float = Field(..., ge=0, le=100)
    memory_utilization_pct: float = Field(..., ge=0, le=100)
    criticality: Criticality
    auto_shutdown_enabled: bool = False


class WorkloadUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=120)
    owner_team: str | None = Field(default=None, min_length=2, max_length=80)
    provider: Provider | None = None
    monthly_cost_usd: float | None = Field(default=None, ge=0)
    cpu_utilization_pct: float | None = Field(default=None, ge=0, le=100)
    memory_utilization_pct: float | None = Field(default=None, ge=0, le=100)
    criticality: Criticality | None = None
    auto_shutdown_enabled: bool | None = None


class Workload(BaseModel):
    id: int
    name: str
    owner_team: str
    provider: Provider
    monthly_cost_usd: float
    cpu_utilization_pct: float
    memory_utilization_pct: float
    criticality: Criticality
    auto_shutdown_enabled: bool
    created_at: datetime
    updated_at: datetime


class Recommendation(BaseModel):
    workload_id: int
    workload_name: str
    recommendation: str
    estimated_savings_usd: float
    priority: Literal["low", "medium", "high"]


class InsightsResponse(BaseModel):
    total_monthly_cost_usd: float
    average_cpu_utilization_pct: float
    average_memory_utilization_pct: float
    low_utilization_workloads: int
    auto_shutdown_coverage_pct: float
    estimated_monthly_savings_usd: float
    recommendations: list[Recommendation]
