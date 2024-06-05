output "node_ips" {
  value = [for vm in vagrant_vm.node : vm.network[0].ip]
}
