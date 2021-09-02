provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = format("%s-rg", var.name)
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = format("%s-network", var.name)
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  resource_group_name  = azurerm_resource_group.main.name
  name                 = format("%s-internal", var.name)
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "main" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = "allowall"

  security_rule {
    name                       = "allowall"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_public_ip" "main_A" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = format("%s-public", var.name)
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Using the older "azurerm_virtual_machine" resource
resource "azurerm_network_interface" "main_A" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = format("%s-nic-a", var.name)

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main_A.id
  }
}

data "azurerm_image" "lookup" {
  resource_group_name = var.azure_image_rg_name
  name                = var.azure_image_name
}

resource "azurerm_virtual_machine" "main_A" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = format("%s-vm-a", var.name)
  network_interface_ids = [
    azurerm_network_interface.main_A.id,
  ]
  vm_size = "Standard_D2s_v3"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = data.azurerm_image.lookup.id
  }

  storage_os_disk {
    name              = "osdisk"
    caching           = data.azurerm_image.lookup.os_disk[0].caching
    disk_size_gb      = data.azurerm_image.lookup.os_disk[0].size_gb
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_windows_config {
  }
}

# azurerm_windows_virtual_machine will not work with an Azure Image with data disks

# resource "azurerm_network_interface" "main_B" {
#   resource_group_name = azurerm_resource_group.main.name
#   location            = azurerm_resource_group.main.location
#   name                = format("%s-nic-b", var.name)

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.main.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# resource "azurerm_windows_virtual_machine" "main_B" {
#   resource_group_name = azurerm_resource_group.main.name
#   location            = azurerm_resource_group.main.location
#   name                = "tstvmb" # format("%s-vm-b", var.name)//cant be more than 15 characters
#   network_interface_ids = [
#     azurerm_network_interface.main_B.id,
#   ]
#   size            = "Standard_D2s_v3"
#   source_image_id = data.azurerm_image.lookup.id

#   admin_username = "testadmin"
#   admin_password = "P@$$w0rd1234!"

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
# }
