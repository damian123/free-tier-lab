# Free Tier Lab

Build useful self-hosted services on genuinely free cloud resources. Oracle Cloud Infrastructure's Ampere A1 Always Free compute is the first provider module: a small Docker host with Terraform, SSH locked to one address, and Always Free ceilings encoded as validations instead of notes in a wiki.

The repository name is provider-neutral so later modules can cover other free tiers without forcing unrelated infrastructure into an Oracle-specific project.

## Capabilities

- One Ubuntu 24.04 ARM VM with **2 OCPUs and 12 GB RAM** by default, or two VMs with **1 OCPU and 6 GB RAM** each.
- A VCN, public subnet, internet gateway, route table, and minimal ingress rules.
- SSH-key-only login, no root login, automatic security upgrades, Fail2ban, and Docker Engine plus Compose from Docker's signed apt repository.
- Terraform checks that reject more than 2 total OCPUs, 12 GB RAM, or 200 GB of boot volumes.
- SSH ingress required as a single IPv4 `/32`; `0.0.0.0/0` and malformed CIDRs fail validation.

The defaults follow Oracle's current Always Free tenancy documentation. Oracle requires Always Free compute in your **home region**, may reclaim idle instances, and may temporarily have no A1 capacity. Always verify the limits and eligible resources shown in your own OCI console before applying. See [Oracle Cloud Free Tier](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier.htm) and [Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm).

## Run

Prerequisites: an OCI account and API signing key for the [OCI Terraform provider](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformproviderconfiguration.htm), Terraform 1.6 or newer, your tenancy's home-region identifier, a compartment OCID, an SSH public key, and your current public IPv4 address. Never commit private keys or `terraform.tfvars`.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your home region, compartment OCID, SSH key,
# and your own public IPv4 address as a /32 for ssh_ingress_cidr.
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Terraform prints the public IP and an SSH command. Cloud-init installs and starts Docker; follow progress with:

```bash
ssh ubuntu@YOUR_PUBLIC_IP
cloud-init status --wait
docker compose version
```

Sample service:

```bash
scp ../examples/compose.yaml ubuntu@YOUR_PUBLIC_IP:~/compose.yaml
ssh ubuntu@YOUR_PUBLIC_IP 'docker compose -f ~/compose.yaml up -d'
curl http://YOUR_PUBLIC_IP
```

| Layout | Instances | Each VM | Good for |
|---|---:|---:|---|
| Default | 1 | 2 OCPU / 12 GB | Docker workloads, simplest operations |
| Split | 2 | 1 OCPU / 6 GB | Isolation, experiments, a tiny two-node setup |

For the split layout, set `instance_count = 2`, `ocpus_per_instance = 1`, and `memory_gb_per_instance = 6` in `terraform.tfvars`.

## Verification

From the repository root:

```bash
terraform -chdir=terraform fmt -check -recursive
make test
```

`make test` runs `terraform init -backend=false`, `terraform validate`, and `terraform test`. The tests accept a documentation-range `/32`, reject world-open SSH, reject a malformed CIDR, and reject two full-size VMs.

GitHub Actions on push and pull request to `main` runs fmt-check, init, validate, and test with Terraform 1.13.5.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the PR checklist.

## Design

- Quota ceilings live in Terraform validations so a plan fails before it can exceed Always Free A1 OCPU, memory, or boot-volume totals.
- `ssh_ingress_cidr` has no default. The example file uses the documentation address `203.0.113.10/32`; replace it with your public IPv4 `/32` before applying.
- Cloud-init hardens the host (SSH keys only, unattended upgrades, Fail2ban) and installs Docker from Docker's apt repository rather than a distro snapshot.
- Two smaller VMs, when requested, are spread across availability domains when the region has more than one.

Good lightweight ARM64 candidates include Caddy, Vaultwarden, Gitea/Forgejo, Uptime Kuma, AdGuard Home, and small personal APIs. Add one service at a time, pin image versions, enable backups, and put public apps behind HTTPS.

## Limitations

- **Out of host capacity:** retry later or try another availability domain in the same home region.
- **Free is a quota, not a billing lock:** as checked against Oracle's Always Free documentation on 2026-08-29, this repository caps 2 total A1 OCPUs, 12 GB RAM, and 200 GB of boot volumes. Limits and eligibility can change. Terraform cannot prevent unrelated OCI resources from costing money. Set an OCI budget alert.
- **Idle reclamation:** Oracle documents that idle Always Free compute can be reclaimed. Run legitimate services and keep backups; do not generate artificial load.
- **ARM compatibility:** use container images that publish `linux/arm64` manifests.
- **Destroy when finished:** `terraform destroy` removes the stack. Confirm the plan before approving it.

Ports 80 and 443 are public for web services. SSH is only the required `ssh_ingress_cidr` `/32`. OCI security lists and the operating-system firewall are separate layers; review both when adding services. Treat `terraform apply` as a real deployment: [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
