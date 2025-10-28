resource "azurerm_resource_group" "whanos" {
  name     = var.resource_group_name_prefix
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "whanos" {
  name                = "whanos-Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.whanos.location
  resource_group_name = azurerm_resource_group.whanos.name
}

resource "azurerm_subnet" "whanos" {
  name                 = "whanos-subnet"
  resource_group_name  = azurerm_resource_group.whanos.name
  virtual_network_name = azurerm_virtual_network.whanos.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "whanos_public_ip" {
  name                = "whanos-public-ip"
  location            = azurerm_resource_group.whanos.location
  resource_group_name = azurerm_resource_group.whanos.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_network_security_group" "whanos_nsg" {
  name                = "whanos_nsg"
  location            = azurerm_resource_group.whanos.location
  resource_group_name = azurerm_resource_group.whanos.name

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
    name                       = "Jenkins"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Kubernetes"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DockerRegistry"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "whanos_nic" {
  name                = "whanos-nic"
  location            = azurerm_resource_group.whanos.location
  resource_group_name = azurerm_resource_group.whanos.name

  ip_configuration {
    name                          = "whanos-nic-config"
    subnet_id                     = azurerm_subnet.whanos.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.whanos_public_ip.id
  }
}

resource "azurerm_subnet_network_security_group_association" "whanos" {
  subnet_id                 = azurerm_subnet.whanos.id
  network_security_group_id = azurerm_network_security_group.whanos_nsg.id
}

resource "azurerm_linux_virtual_machine" "whanos_vm" {
  name                = "whanos-vm"
  resource_group_name = azurerm_resource_group.whanos.name
  location            = azurerm_resource_group.whanos.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  
  network_interface_ids = [
    azurerm_network_interface.whanos_nic.id,
  ]

  admin_ssh_key { // clé pour lautentification
    username   = "adminuser"
    public_key = file("~/.ssh/whanos_key.pub")
  }

  os_disk { // disque systeme d'exploi
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference { // image unbuntu a utiliser 
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
