# outputs.tf
output "web_server_public_ip" {
  value = azurerm_public_ip.web_server_public_ip.ip_address
}

output "db_server_private_ip" {
  value = azurerm_network_interface.db_nic.private_ip_address
}
