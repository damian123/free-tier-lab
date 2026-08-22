data "oci_identity_availability_domains" "available" {
  compartment_id = var.compartment_ocid
}

data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  total_ocpus     = var.instance_count * var.ocpus_per_instance
  total_memory_gb = var.instance_count * var.memory_gb_per_instance
  total_boot_gb   = var.instance_count * var.boot_volume_gb
}

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.42.0.0/16"]
  display_name   = "${var.name_prefix}-vcn"
  dns_label      = "freearm"
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.name_prefix}-internet-gateway"
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.name_prefix}-public-routes"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.name_prefix}-public-security"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    source   = var.ssh_ingress_cidr
    protocol = "6"
    tcp_options {
      min = 22
      max = 22
    }
  }

  dynamic "ingress_security_rules" {
    for_each = toset([80, 443])
    content {
      source   = "0.0.0.0/0"
      protocol = "6"
      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "1"
    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = "10.42.1.0/24"
  display_name               = "${var.name_prefix}-public-subnet"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_instance" "arm" {
  count               = var.instance_count
  availability_domain = data.oci_identity_availability_domains.available.availability_domains[count.index % length(data.oci_identity_availability_domains.available.availability_domains)].name
  compartment_id      = var.compartment_ocid
  display_name        = format("%s-%02d", var.name_prefix, count.index + 1)
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.ocpus_per_instance
    memory_in_gbs = var.memory_gb_per_instance
  }

  create_vnic_details {
    assign_public_ip = true
    display_name     = format("%s-vnic-%02d", var.name_prefix, count.index + 1)
    hostname_label   = format("arm%02d", count.index + 1)
    subnet_id        = oci_core_subnet.public.id
  }

  source_details {
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    source_type             = "image"
    boot_volume_size_in_gbs = var.boot_volume_gb
  }

  metadata = {
    ssh_authorized_keys = trimspace(var.ssh_public_key)
    user_data           = base64encode(file("${path.module}/../cloud-init/cloud-config.yaml"))
  }

  lifecycle {
    precondition {
      condition     = local.total_ocpus <= 2 && local.total_memory_gb <= 12
      error_message = "Requested A1 compute exceeds the Always Free tenancy ceiling of 2 OCPUs and 12 GB RAM."
    }

    precondition {
      condition     = local.total_boot_gb <= 200
      error_message = "Requested boot volumes exceed the documented 200 GB Always Free block-volume allowance."
    }
  }
}
