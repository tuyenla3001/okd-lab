# Khai báo provider
provider "vsphere" {
  user                 = "administrator@vsphere.local"
  password             = "XPLAT@53rv1c3"
  vsphere_server       = "10.15.242.222"
  allow_unverified_ssl = true
}

variable "datacenter" {
  default = "OKD-LAB-DC"
}

data "vsphere_datacenter" "datacenter" {
  name = var.datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = "OKD-LAB-Cluster"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  name          = "OKD-LAB"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# Datastore
data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# Network
data "vsphere_network" "network" {
  name          = "VM Network - 242"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network1" {
  name          = "VLAN225"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# VM Template
data "vsphere_virtual_machine" "template" {
  name          = "vm-template-centos"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# VM Template
data "vsphere_virtual_machine" "template1" {
  name          = "centos8-template"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

#### okd-lab-bastion ####
resource "vsphere_virtual_machine" "okd-lab-bastion" {
  name             = "okd-lab-bastion"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 4
  memory           = 8192
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  disk {
    label            = "disk0"
    size             = 200
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        host_name = "okd-lab-bastion"
        domain    = ""
      }
      network_interface {
        ipv4_address = "10.15.242.241"
        ipv4_netmask = 24
      }
      ipv4_gateway = "10.15.242.1"
      dns_server_list = ["8.8.8.8", "8.8.4.4"]
    }  
  }
}

  provisioner "local-exec" {
    command = "ansible-playbook --ssh-extra-args '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -i '10.0.0.2,' --private-key ~/.ssh/id_rsa -T 300 ~/github/okd-lab/ansible/bastion/terraform.yml"
  }

}
