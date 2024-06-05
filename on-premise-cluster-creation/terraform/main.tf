provider "vagrant" {
  version = "~> 2.0"
}

resource "vagrant_vm" "node" {
  count = 3
  name  = "node-${count.index + 1}"

  box     = "ubuntu/bionic64"
  memory  = 1024
  cpus    = 2
  network {
    type = "private_network"
    ip   = "192.168.50.${count.index + 125}"
  }
}

output "node_ips" {
  value = [for vm in vagrant_vm.node : vm.network[0].ip]
}
