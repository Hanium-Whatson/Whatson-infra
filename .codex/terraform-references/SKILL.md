---
name: terraform-seven-references
description: Diagnose and solve Terraform/OpenTofu work by routing to one of seven reference guides (ci-cd-workflows, code-patterns, module-patterns, quick-reference, security-compliance, state-management, testing-frameworks). Use when writing, reviewing, debugging, or operating Terraform/OpenTofu modules, pipelines, tests, security checks, and state workflows.
---

# Terraform Seven References Skill

Follow this workflow.

1. Capture context first.
- Identify runtime: `terraform` or `tofu`
- Record exact version and provider versions
- Identify backend type and execution path (local/CI/Cloud)
- Mark environment criticality (dev/staging/prod)

2. Classify the primary failure mode.
- CI pipeline mismatch or artifact flow issue -> `references/ci-cd-workflows.md`
- HCL structure, `count`/`for_each`, `moved`, version constraints -> `references/code-patterns.md`
- Module architecture, variable/output contracts, reuse boundaries -> `references/module-patterns.md`
- Need fast commands/decision shortcuts/troubleshooting lookup -> `references/quick-reference.md`
- Secret exposure, policy checks, compliance hardening -> `references/security-compliance.md`
- Locking, backend migration, drift, recovery, isolation -> `references/state-management.md`
- Test strategy, native tests, Terratest, plan-test limits -> `references/testing-frameworks.md`

3. Load only the matching reference file.
- Do not preload all seven files.
- If the request spans multiple risk categories, load only the minimum additional file.

4. Propose a remediation with controls.
- Explain the chosen fix and tradeoff.
- Add guardrails: validation commands, approvals, rollback notes.
- Avoid direct production apply without reviewed plan artifact.

5. End every response with this output contract.
- Assumptions and version floor
- Risk category addressed
- Chosen remediation and tradeoffs
- Validation plan with exact commands
- Rollback notes for state/destructive changes

## Reference Index

- `references/ci-cd-workflows.md`
- `references/code-patterns.md`
- `references/module-patterns.md`
- `references/quick-reference.md`
- `references/security-compliance.md`
- `references/state-management.md`
- `references/testing-frameworks.md`
