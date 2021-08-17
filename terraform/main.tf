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


# Using the older "azurerm_virtual_machine" resource
resource "azurerm_network_interface" "main_A" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = format("%s-nic-a", var.name)

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
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
    id = var.azure_image_id
  }

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_data_disk {
    name              = "datadisk1"
    lun               = 0
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb      = 128
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
#   source_image_id = var.azure_image_id

#   admin_username = "testadmin"
#   admin_password = "P@$$w0rd1234!"

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
# }
