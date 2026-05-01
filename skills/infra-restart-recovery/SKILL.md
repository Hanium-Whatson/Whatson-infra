---
name: infra-restart-recovery
description: Recover and verify Terraform-based infrastructure after it has been brought down and recreated. Use when users ask to recover services after terraform destroy/apply, infra teardown/redeploy, or when resources are recreated and post-apply checks, reconfiguration, and validation must run automatically.
---

# Infra Restart Recovery

Execute this workflow after infrastructure is destroyed and recreated.

## Use References

- For training stack recovery, load `references/checklist-training.md`.
- For serving stack recovery, load `references/checklist-serving.md`.
- If the user names a specific environment (`dev`, `stg`, `prod`), apply that environment path first.

## Inputs

- Terraform root/environment path (for example `terraform/environments/dev/training`)
- Target stack name (training, serving, monitoring)
- Critical endpoints and health checks to validate

## Workflow

1. Confirm state and workspace.
- Run `terraform init` if needed.
- Run `terraform workspace show` and verify target workspace.

2. Reconcile infrastructure.
- Run `terraform plan` and inspect drift.
- Run `terraform apply` for pending changes.

3. Re-bind runtime dependencies.
- Re-check generated resource identifiers (VPC IDs, subnet IDs, SG IDs, queue ARNs, function names, bucket names).
- Re-apply dependent configs that reference recreated IDs.

4. Validate platform health.
- Confirm core resources are active (network, compute, data stores, queues, schedulers).
- Run service-specific health checks and smoke tests.

5. Validate scheduled/async paths.
- Verify EventBridge schedules and Lambda triggers.
- Verify DLQ and queue attributes.

6. Report and handoff.
- Summarize recreated resources, changed identifiers, and follow-up actions.
- List any manual rotations or secrets sync required.

## Safety Rules

- Never run destroy operations unless explicitly requested.
- Prefer read-first checks before mutation (`plan` before `apply`).
- If production is targeted, require explicit confirmation before apply.

## Output Format

Return:
- Environment and workspace
- Applied changes summary
- New/changed IDs and endpoints
- Validation results (pass/fail)
- Remaining manual actions
