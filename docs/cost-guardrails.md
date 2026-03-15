# Cost Guardrails

## Mandatory Practices

- Keep AKS as ephemeral: destroy after each learning session.
- Use 1 node only in dev.
- Keep Log Analytics retention low (7 days).
- Use ACR Basic tier only.
- Keep Prometheus retention low (2 days in chart values).

## Alerts

- Resource group budget set to 15 USD monthly.
- Notifications at 80% actual and 100% forecast.

## Cost Risks

- Public load balancer and persistent uptime can increase costs quickly.
- Repeated image pushes and logs can add up if environment stays active.
- Observability stack (Prometheus/Grafana/Alertmanager) consumes memory and CPU if left running continuously.

## Optimization Options

- Reduce deployment frequency.
- Keep only essential observability for active practice windows.
- If budget remains strict, replace AKS with Container Apps for daily use, keep AKS for specific learning labs.
