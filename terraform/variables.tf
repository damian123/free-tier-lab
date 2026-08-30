variable "region" {
  description = "OCI home region, for example ap-tokyo-1. Always Free compute must be created in the home region."
  type        = string
}

variable "compartment_ocid" {
  description = "OCID of the compartment in which resources will be created."
  type        = string
}

variable "ssh_public_key" {
  description = "OpenSSH public key installed for the ubuntu user."
  type        = string
  sensitive   = true
}

variable "instance_count" {
  description = "One larger VM or two smaller VMs."
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2], var.instance_count)
    error_message = "instance_count must be 1 or 2 to remain within the documented Always Free A1 limit."
  }
}

variable "ocpus_per_instance" {
  description = "A1 OCPUs per instance. Defaults to 2 for one VM; set to 1 when using two VMs."
  type        = number
  default     = 2

  validation {
    condition     = var.ocpus_per_instance >= 1 && var.ocpus_per_instance <= 2
    error_message = "ocpus_per_instance must be between 1 and 2."
  }
}

variable "memory_gb_per_instance" {
  description = "RAM in GB per instance. Defaults to 12 for one VM; set to 6 when using two VMs."
  type        = number
  default     = 12

  validation {
    condition     = var.memory_gb_per_instance >= 1 && var.memory_gb_per_instance <= 12
    error_message = "memory_gb_per_instance must be between 1 and 12."
  }
}

variable "boot_volume_gb" {
  description = "Boot volume per VM. OCI's documented minimum is 47 GB."
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_gb >= 47 && var.boot_volume_gb <= 100
    error_message = "boot_volume_gb must be between 47 and 100 GB."
  }
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to SSH. Supply your public IPv4 address as x.x.x.x/32."
  type        = string

  validation {
    condition = alltrue([
      can(cidrhost(var.ssh_ingress_cidr, 0)),
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/32$", var.ssh_ingress_cidr))
    ])
    error_message = "ssh_ingress_cidr must be a valid IPv4 /32 for one public address; 0.0.0.0/0 and malformed CIDRs are not allowed."
  }
}

variable "name_prefix" {
  description = "Prefix used for OCI resource display names."
  type        = string
  default     = "free-arm"
}
