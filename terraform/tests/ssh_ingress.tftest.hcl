mock_provider "oci" {
  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [
        {
          name = "example-AD-1"
        }
      ]
    }
  }

  mock_data "oci_core_images" {
    defaults = {
      images = [
        {
          id = "ocid1.image.oc1..example"
        }
      ]
    }
  }
}

variables {
  region             = "ap-tokyo-1"
  compartment_ocid   = "ocid1.compartment.oc1..example"
  ssh_public_key     = "ssh-ed25519 AAAAexample"
  ssh_ingress_cidr   = "203.0.113.10/32"
  instance_count     = 1
  ocpus_per_instance = 2
}

run "accept_restricted_ssh_cidr" {
  command = plan
}

run "reject_world_open_ssh" {
  command = plan

  variables {
    ssh_ingress_cidr = "0.0.0.0/0"
  }

  expect_failures = [var.ssh_ingress_cidr]
}

run "reject_malformed_ssh_cidr" {
  command = plan

  variables {
    ssh_ingress_cidr = "not-a-cidr"
  }

  expect_failures = [var.ssh_ingress_cidr]
}

run "reject_two_full_size_vms" {
  command = plan

  variables {
    instance_count = 2
  }

  expect_failures = [oci_core_instance.arm]
}
