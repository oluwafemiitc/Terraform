output "load_balancer_public_ip" {
  value       = azurerm_public_ip.lb_public_ip.ip_address
  description = "The public IP address of the load balancer"
}

output "vm_private_ips" {
  value = azurerm_network_interface.vm_nic[*].private_ip_address
  description = "The private IP addresses of the VMs"
}

# SSH Private Key Output (be careful with this in production)
output "ssh_private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}