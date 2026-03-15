from statistics import mean

from .schemas import InsightsResponse, Recommendation, Workload


def build_recommendations(workloads: list[Workload]) -> list[Recommendation]:
    recommendations: list[Recommendation] = []

    for item in workloads:
        util_score = (item.cpu_utilization_pct + item.memory_utilization_pct) / 2

        if util_score < 25:
            estimated = round(item.monthly_cost_usd * 0.35, 2)
            recommendations.append(
                Recommendation(
                    workload_id=item.id,
                    workload_name=item.name,
                    recommendation="Rightsize compute tier or move to burstable instances.",
                    estimated_savings_usd=estimated,
                    priority="high",
                )
            )

        if not item.auto_shutdown_enabled and item.criticality != "high":
            estimated = round(item.monthly_cost_usd * 0.15, 2)
            recommendations.append(
                Recommendation(
                    workload_id=item.id,
                    workload_name=item.name,
                    recommendation="Enable off-hours auto-shutdown for non-critical workload.",
                    estimated_savings_usd=estimated,
                    priority="medium",
                )
            )

        if item.provider == "azure" and util_score < 45:
            estimated = round(item.monthly_cost_usd * 0.08, 2)
            recommendations.append(
                Recommendation(
                    workload_id=item.id,
                    workload_name=item.name,
                    recommendation="Evaluate Reserved Instances / Savings Plan for baseline usage.",
                    estimated_savings_usd=estimated,
                    priority="low",
                )
            )

    recommendations.sort(key=lambda value: value.estimated_savings_usd, reverse=True)
    return recommendations


def calculate_insights(workloads: list[Workload]) -> InsightsResponse:
    if not workloads:
        return InsightsResponse(
            total_monthly_cost_usd=0,
            average_cpu_utilization_pct=0,
            average_memory_utilization_pct=0,
            low_utilization_workloads=0,
            auto_shutdown_coverage_pct=0,
            estimated_monthly_savings_usd=0,
            recommendations=[],
        )

    total_cost = round(sum(item.monthly_cost_usd for item in workloads), 2)
    avg_cpu = round(mean(item.cpu_utilization_pct for item in workloads), 2)
    avg_mem = round(mean(item.memory_utilization_pct for item in workloads), 2)
    low_util = sum(1 for item in workloads if ((item.cpu_utilization_pct + item.memory_utilization_pct) / 2) < 30)
    auto_shutdown_coverage = round((sum(1 for item in workloads if item.auto_shutdown_enabled) / len(workloads)) * 100, 2)

    recommendations = build_recommendations(workloads)
    estimated_savings = round(sum(item.estimated_savings_usd for item in recommendations), 2)

    return InsightsResponse(
        total_monthly_cost_usd=total_cost,
        average_cpu_utilization_pct=avg_cpu,
        average_memory_utilization_pct=avg_mem,
        low_utilization_workloads=low_util,
        auto_shutdown_coverage_pct=auto_shutdown_coverage,
        estimated_monthly_savings_usd=estimated_savings,
        recommendations=recommendations,
    )
