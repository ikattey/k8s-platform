output "network_id" {
  description = "ID of the private network"
  value       = openstack_networking_network_v2.private.id
}

output "subnet_id" {
  description = "ID of the private subnet"
  value       = openstack_networking_subnet_v2.private.id
}

output "subnet_cidr" {
  description = "CIDR block of the private subnet"
  value       = openstack_networking_subnet_v2.private.cidr
}

output "router_id" {
  description = "ID of the OpenStack router"
  value       = openstack_networking_router_v2.router.id
}

output "gateway_ip" {
  description = "Gateway IP address (first usable IP in the subnet, assigned to the router)"
  value       = cidrhost(var.subnet_cidr, 1)
}
