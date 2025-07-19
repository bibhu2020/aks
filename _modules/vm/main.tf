resource "azurerm_public_ip" "public_ip" {
  count = var.enable == true ? 1 : 0
  name                = "${var.name}-public-ip"
  resource_group_name = var.rg
  location            = var.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "res" {
  count = var.enable == true ? 1 : 0
  name                = "${var.name}-nic"
  resource_group_name = var.rg
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.vnet_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[0].id 
  }
}

resource "azurerm_windows_virtual_machine" "res" {
  count = var.enable == true ? 1 : 0
  name                = var.name
  resource_group_name = var.rg
  location            = var.location
  size                = var.size
  admin_username      = var.username
  admin_password      = var.password
  network_interface_ids = [
    azurerm_network_interface.res[0].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  tags               = var.tags
}

# resource "azurerm_virtual_machine_extension" "jit_vm_access" {
#   name = "jit-vm-access"
#   virtual_machine_id = azurerm_windows_virtual_machine.res.id
#   publisher = "Microsoft.Azure.Security"
#   type = "JitNetworkAccess"
#   type_handler_version = "1.4"
#   auto_upgrade_minor_version = true
#   settings = jsonencode({
#     "durationInSeconds" = 7200
#   })
# }

