# Runbook: Deploy and Destroy

## Deploy

1. Ensure domain and DNS are prepared for ingress.
2. Run `./scripts/deploy.sh`.
3. Verify:

- `kubectl get pods -n dev`
- `kubectl get ingress -n dev`
- `kubectl get pods -n monitoring`
- TLS certificate issuance from cert-manager.

## Destroy

1. Confirm no active learning session is in progress.
2. Run `./scripts/destroy.sh --yes`.
3. Verify Azure resources are removed except Terraform backend resources.

## Failure Handling

- If Terraform fails, rerun after fixing variable/provider issues.
- If ingress/cert-manager fails, inspect:
  - `kubectl get pods -n ingress-nginx`
  - `kubectl get pods -n cert-manager`
- If monitoring is unhealthy, inspect:
  - `kubectl get pods -n monitoring`
  - `kubectl logs -n monitoring deploy/kube-prometheus-stack-operator`
- If rollout fails, execute rollback command and inspect pod events.
