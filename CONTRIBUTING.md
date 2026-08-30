# Contributing

Keep provider modules isolated. Do not add a second cloud until its current free-tier limits are checked against official docs and encoded as Terraform validations.

## Checks

```bash
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
terraform -chdir=terraform test
```

Or `make fmt` and `make validate` from the repository root.

## Pull requests

`main` is protected. Keep changes focused: one provider, guardrail, or docs fix per PR.

- [ ] `terraform fmt -check -recursive` passes
- [ ] `terraform validate` and `terraform test` pass
- [ ] README limits and dates match the code
- [ ] No tenancy OCIDs, private keys, or live `terraform.tfvars`
