# main.tf

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-rg"
  location = var.location
}

# Virtual Network with two subnets
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "${var.project_name}-public-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "${var.project_name}-private-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Groups
resource "azurerm_network_security_group" "public_nsg" {
  name                = "${var.project_name}-public-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "private_nsg" {
  name                = "${var.project_name}-private-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowAppToDB"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.1.0/24" # Public subnet range
    destination_address_prefix = "10.0.2.0/24" # Private subnet range
  }
}

# Network Interfaces
resource "azurerm_network_interface" "web_nic" {
  name                = "${var.project_name}-web-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "web-ip-config"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_server_public_ip.id
  }
}

resource "azurerm_network_interface" "db_nic" {
  name                = "${var.project_name}-db-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "db-ip-config"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Public IP for Web Server
resource "azurerm_public_ip" "web_server_public_ip" {
  name                = "${var.project_name}-web-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Web Server VM
resource "azurerm_linux_virtual_machine" "web_server" {
  name                  = "${var.project_name}-web"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.web_nic.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    Environment = "Testing"
  }
}

# Web Server VM Extension for Flask App
resource "azurerm_virtual_machine_extension" "web_server_extension" {
  name                 = "web-server-extension"
  virtual_machine_id   = azurerm_linux_virtual_machine.web_server.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  
  settings = <<SETTINGS
    {
      "commandToExecute": "wget https://terrastoragea.blob.core.windows.net/terracontainer/flaskApp.py -O /tmp/flaskApp.py && sudo apt update && sudo apt install -y python3-pip && pip3 install flask psycopg2-binary && sudo python3 /tmp/flaskApp.py"
    }
  SETTINGS
}

# Database Server VM
resource "azurerm_linux_virtual_machine" "db_server" {
  name                  = "${var.project_name}-db"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.db_nic.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    Environment = "Testing"
  }
}

# Database Server VM Extension for PostgreSQL Setup
resource "azurerm_virtual_machine_extension" "db_server_extension" {
  name                 = "db-server-extension"
  virtual_machine_id   = azurerm_linux_virtual_machine.db_server.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  
  settings = <<SETTINGS
    {
      "commandToExecute": "wget https://terrastoragea.blob.core.windows.net/terracontainer/db-user-data.sh -O /tmp/db-user-data.sh && sudo bash /tmp/db-user-data.sh"
    }
  SETTINGS
}

