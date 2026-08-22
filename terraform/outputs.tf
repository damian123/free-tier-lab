output "public_ips" {
  description = "Public IP address of each ARM VM."
  value       = oci_core_instance.arm[*].public_ip
}

output "ssh_commands" {
  description = "Convenient SSH commands after cloud-init has finished."
  value       = [for vm in oci_core_instance.arm : "ssh ubuntu@${vm.public_ip}"]
}

output "resource_budget" {
  description = "Requested resources for a quick Always Free sanity check."
  value = {
    instances     = var.instance_count
    total_ocpus   = local.total_ocpus
    total_ram_gb  = local.total_memory_gb
    total_boot_gb = local.total_boot_gb
  }
}
