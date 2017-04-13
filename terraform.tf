# create a resource group if it doesn't exist
resource "azurerm_resource_group" "demoterraform" {
  name     = "${var.terraform_resource_group}"
  location = "${var.terraform_azure_region}"
}

# create virtual network
resource "azurerm_virtual_network" "demoterraformnetwork" {
  name                = "tfvn"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.terraform_azure_region}"
  resource_group_name = "${azurerm_resource_group.demoterraform.name}"
}

# create subnet
resource "azurerm_subnet" "demoterraformsubnet" {
  name                 = "tfsub"
  resource_group_name  = "${azurerm_resource_group.demoterraform.name}"
  virtual_network_name = "${azurerm_virtual_network.demoterraformnetwork.name}"
  address_prefix       = "10.0.2.0/24"
}

# create public IPs
resource "azurerm_public_ip" "demoterraformips" {
  name                         = "demoterraformip"
  location                     = "${var.terraform_azure_region}"
  resource_group_name          = "${azurerm_resource_group.demoterraform.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${azurerm_resource_group.demoterraform.name}"

  tags {
    environment = "TerraformDemo"
  }
}

# create network interface
resource "azurerm_network_interface" "demoterraformnic" {
  name                = "tfni"
  location            = "${var.terraform_azure_region}"
  resource_group_name = "${azurerm_resource_group.demoterraform.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.demoterraformsubnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.2.5"
    public_ip_address_id          = "${azurerm_public_ip.demoterraformips.id}"
  }
}

# create virtual machine
resource "azurerm_virtual_machine" "demoterraformvm" {
  name                  = "terraformvm"
  location              = "${var.terraform_azure_region}"
  resource_group_name   = "${azurerm_resource_group.demoterraform.name}"
  network_interface_ids = ["${azurerm_network_interface.demoterraformnic.id}"]
  vm_size = "Standard_A0"

  storage_image_reference {
    publisher = "CoreOS"
    offer     = "CoreOS"
    sku       = "Stable"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "core"
    admin_username = "core"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  os_profile_secrets {
    source_vault_id = "${var.terraform_keyvault_source_vault_id}"

    vault_certificates = {
      certificate_url = "${var.terraform_keyvault_certificate_url}"
    }
  }

  tags {
    environment = "staging"
  }
}