provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aiops-poc" {
  name     = "aiops-poc-resources"
  location = "East US"
}

resource "azurerm_virtual_network" "aiops-poc" {
  name                = "aiops-poc-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.aiops-poc.location
  resource_group_name = azurerm_resource_group.aiops-poc.name
}

resource "azurerm_subnet" "aiops-poc" {
  name                 = "aiops-poc-subnet"
  resource_group_name  = azurerm_resource_group.aiops-poc.name
  virtual_network_name = azurerm_virtual_network.aiops-poc.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "aiops-poc" {
  name                = "aiops-poc-nic"
  location            = azurerm_resource_group.aiops-poc.location
  resource_group_name = azurerm_resource_group.aiops-poc.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.aiops-poc.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "aiops-poc" {
  name                = "aiops-poc-vm"
  resource_group_name = azurerm_resource_group.aiops-poc.name
  location            = azurerm_resource_group.aiops-poc.location
  size                = "Standard_D8s_v5" # 8 vCPUs, 32 GiB RAM (closest for 8 vCPU/16GB RAM, D8s_v3 is also a choice with 8vCPU/32GB RAM)
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.aiops-poc.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "aiops-poc-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "24_04-lts-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
}

output "vm_public_ip" {
  value = azurerm_network_interface.aiops-poc.private_ip_address
}
