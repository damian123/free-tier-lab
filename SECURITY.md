# Security

This repository is Terraform you apply in your own Oracle Cloud tenancy. It can create public VMs. Treat `terraform apply` as a real deployment.

## Reporting a vulnerability

Open a [GitHub security advisory](https://github.com/damian123/free-tier-lab/security/advisories/new) or contact the account owner through GitHub. Do not file a public issue for credential leaks or tenancy exposure.

## Before you apply

- Never commit `terraform.tfvars`, private keys, or API signing keys.
- Set `ssh_ingress_cidr` to your public IPv4 `/32`. The example address is documentation-only (`203.0.113.10/32`).
- Set an OCI budget alert. Always Free is a quota, not a billing lock.
- Destroy the stack when you are finished: `terraform destroy`.
