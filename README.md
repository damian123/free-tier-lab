# OCI Free ARM Stack

Provision a small, security-conscious Docker host on Oracle Cloud Infrastructure's Ampere A1 Always Free compute using Terraform.

> Inspired by the project brief that started this repository: make genuinely useful internet services easy to run on Oracle's free ARM capacity, with the free limits captured as code instead of tribal knowledge.

## What you get

- One Ubuntu 24.04 ARM VM with **2 OCPUs and 12 GB RAM** by default.
- An optional two-VM layout with **1 OCPU and 6 GB RAM each**.
- A VCN, public subnet, internet gateway, route table, and minimal ingress rules.
- SSH-key-only login, no root login, automatic security upgrades, Fail2ban, Docker, and Docker Compose.
- Terraform checks that reject more than 2 total OCPUs, 12 GB RAM, or 200 GB of boot volumes.

The defaults follow Oracle's current Always Free tenancy documentation. Oracle requires Always Free compute in your **home region**, may reclaim idle instances, and may temporarily have no A1 capacity. Always verify the limits and eligible resources shown in your own OCI console before applying. See [Oracle Cloud Free Tier](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier.htm) and [Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm).

## Prerequisites

1. An OCI account and an API signing key configured for the [OCI Terraform provider](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformproviderconfiguration.htm).
2. Terraform 1.6 or newer.
3. Your tenancy's home-region identifier and a compartment OCID.
4. An SSH public key. Never commit private keys or `terraform.tfvars`.

## Deploy

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your home region, compartment OCID, SSH key,
# and preferably your own public IP as a /32 for ssh_ingress_cidr.
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

To try the sample service:

```bash
scp ../examples/compose.yaml ubuntu@YOUR_PUBLIC_IP:~/compose.yaml
ssh ubuntu@YOUR_PUBLIC_IP 'docker compose -f ~/compose.yaml up -d'
curl http://YOUR_PUBLIC_IP
```

## One VM or two?

| Layout | Instances | Each VM | Good for |
|---|---:|---:|---|
| Default | 1 | 2 OCPU / 12 GB | Docker workloads, simplest operations |
| Split | 2 | 1 OCPU / 6 GB | Isolation, experiments, a tiny two-node setup |

For the split layout, set `instance_count = 2`, `ocpus_per_instance = 1`, and `memory_gb_per_instance = 6` in `terraform.tfvars`.

## Capacity and cost guardrails

- **Out of host capacity:** retry later or try another availability domain in the same home region. This configuration distributes two VMs across available domains when possible.
- **Free is a quota, not a billing lock:** Terraform constrains the resources in this repository, but it cannot prevent unrelated OCI resources or future pricing changes from costing money. Set an OCI budget alert and review the plan.
- **Idle reclamation:** Oracle documents that idle Always Free compute can be reclaimed. Run legitimate services and keep backups; do not generate artificial load.
- **ARM compatibility:** use container images that publish `linux/arm64` manifests.
- **Destroy when finished:** `terraform destroy` removes the stack. Confirm the plan before approving it.

## Next useful services

Good lightweight ARM64 candidates include Caddy, Vaultwarden, Gitea/Forgejo, Uptime Kuma, AdGuard Home, and small personal APIs. Add one service at a time, pin image versions, enable backups, and put public apps behind HTTPS rather than exposing arbitrary ports.

## Security notes

Ports 80 and 443 are public for web services. SSH is controlled by `ssh_ingress_cidr`; the example uses a documentation-only IP, while the variable default is open so first-time users do not lock themselves out. Restrict it to your public address (`x.x.x.x/32`) before applying. OCI security lists and the operating-system firewall are separate layers; review both when adding services.

## License

[MIT](LICENSE)
