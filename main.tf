resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Resource Group
data "azurerm_resource_group" "nginx_lb_rg" {
  name     = var.resource_group_name
  //location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "nginx_vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = data.azurerm_resource_group.nginx_lb_rg.location
  resource_group_name = data.azurerm_resource_group.nginx_lb_rg.name
}

# Subnet
resource "azurerm_subnet" "nginx_subnet" {
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_resource_group.nginx_lb_rg.name
  virtual_network_name = azurerm_virtual_network.nginx_vnet.name
  address_prefixes     = var.subnet_address_prefixes
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "nginx-lb-public-ip"
  location            = data.azurerm_resource_group.nginx_lb_rg.location
  resource_group_name = data.azurerm_resource_group.nginx_lb_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Security Group
resource "azurerm_network_security_group" "nginx_nsg" {
  name                = "nginx-nsg"
  location            = data.azurerm_resource_group.nginx_lb_rg.location
  resource_group_name = data.azurerm_resource_group.nginx_lb_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interfaces (Private IPs Only)
resource "azurerm_network_interface" "vm_nic" {
  count               = var.vm_count
  name                = "nginx-vm-nic-${count.index + 1}"
  location            = data.azurerm_resource_group.nginx_lb_rg.location
  resource_group_name = data.azurerm_resource_group.nginx_lb_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.nginx_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Network Interface Security Group Association
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  count                     = var.vm_count
  network_interface_id      = data.azurerm_network_interface.vm_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nginx_nsg.id
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "nginx_vm" {
  count               = var.vm_count
  name                = "nginx-vm-${count.index + 1}"
  resource_group_name = data.azurerm_resource_group.nginx_lb_rg.name
  location            = data.azurerm_resource_group.nginx_lb_rg.location
  size                = var.vm_size
  admin_username      = var.admin_username
  
  # SSH Key Authentication
  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }
  
  network_interface_ids = [
    azurerm_network_interface.vm_nic[count.index].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Nginx installation script
  custom_data = base64encode(<<-EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
echo "Hello from VM ${count.index + 1}" | sudo tee /var/www/html/index.html
EOF
  )
}

# Load Balancer
resource "azurerm_lb" "nginx_lb" {
  name                = "nginx-load-balancer"
  location            = data.azurerm_resource_group.nginx_lb_rg.location
  resource_group_name = data.azurerm_resource_group.nginx_lb_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.nginx_lb.id
  name            = "BackEndAddressPool"
}

# Backend Address Pool Association
resource "azurerm_network_interface_backend_address_pool_association" "pool_association" {
  count                   = 2
  network_interface_id    = data.azurerm_network_interface.vm_nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

# Load Balancing Rule
resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.nginx_lb.id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}

# Health Probe
resource "azurerm_lb_probe" "http_probe" {
  loadbalancer_id = azurerm_lb.nginx_lb.id
  name            = "http-probe"
  port            = 80
}