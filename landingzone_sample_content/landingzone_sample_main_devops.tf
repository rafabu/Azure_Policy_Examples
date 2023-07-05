######################################################
# Resource Group (DevOps)
######################################################
data "azurecaf_name" "rg-devops" {
  name          = var.resource_name_service
  resource_type = "azurerm_resource_group"
  prefixes = [
    var.resource_name_environment
  ]
  suffixes = [
    "devops"
  ]
  random_length = 0
  separator     = "-"
  clean_input   = true
  use_slug      = true
}
resource "azurerm_resource_group" "rg-devops" {
  name     = data.azurecaf_name.rg-devops.result
  location = var.resource_location

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# ######################################################
# # Virtual Machine
#     - NIC
#     - Windows Server
# ######################################################
data "azurecaf_name" "vm-devops" {
  name          = replace(var.resource_name_service, "-", "")
  resource_type = "azurerm_windows_virtual_machine"
  prefixes = [
    replace(var.resource_name_environment, "-", "")
  ]
  suffixes = [
    "dvps",
    format("%01.0f", 1)
  ]
  random_length = 0
  separator     = ""
  clean_input   = true
  # don't add vm (to preserve letters)
  use_slug = false
}
data "azurecaf_name" "vm-devops-nic" {
  name          = ""
  resource_type = "azurerm_network_interface"
  prefixes = [
    data.azurecaf_name.vm-devops.result
  ]
  suffixes = [
    format("%01.0f", 1)
  ]
  random_length = 0
  separator     = "-"
  clean_input   = true
  use_slug      = true
}
resource "random_password" "vm-devops-password" {
  length           = 24
  lower            = true
  upper            = true
  numeric          = true
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "+-*%&?/@£$"
}
resource "azurerm_network_interface" "vm-devops-nic" {

  name = data.azurecaf_name.vm-devops-nic.result

  location            = azurerm_resource_group.rg-devops.location
  resource_group_name = azurerm_resource_group.rg-devops.name

  dns_servers                   = null
  enable_accelerated_networking = null
  enable_ip_forwarding          = false

  ip_configuration {
    name                          = "ipv4"
    primary                       = true
    subnet_id                     = "/subscriptions/73e7819b-1f47-457c-b6d0-ddcc1627c6ce/resourceGroups/sunday_number_09/providers/Microsoft.Network/virtualNetworks/sunday_09/subnets/default"
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
    public_ip_address_id          = null
  }

  tags = azurerm_resource_group.rg-devops.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
resource "azurerm_windows_virtual_machine" "vm-devops" {
  name                = data.azurecaf_name.vm-devops.result
  computer_name       = null
  location            = azurerm_resource_group.rg-devops.location
  resource_group_name = azurerm_resource_group.rg-devops.name
  # availability sets can only be used on non-zonal VMs
  availability_set_id = null
  size                = "Standard_B2ms"
  admin_username      = "localadmin"
  admin_password      = random_password.vm-devops-password.result
  custom_data         = null
  user_data           = null
  # manual patch_mode mandates automatic updates be false
  enable_automatic_updates = true
  patch_mode               = "AutomaticByOS"
  patch_assessment_mode    = "ImageDefault"
  timezone                 = null
  license_type             = "None"
  # must not be enabled if ADE is used
  encryption_at_host_enabled = false
  # NoZone: null - assure pre-zonal VMs do not drift (and do not accidentally re-create)
  zone = null

  identity {
    type = "SystemAssigned"
  }

  network_interface_ids = [
    azurerm_network_interface.vm-devops-nic.id
  ]

  source_image_id = null
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  os_disk {
    name                 = format("%s-osdisk", data.azurecaf_name.vm-devops.result)
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = null
  }

  tags = azurerm_resource_group.rg-devops.tags

  lifecycle {
    ignore_changes = [
      tags,
      admin_password,
      # ignore to not trigger replacement after a successful restore from backup
      source_image_reference
    ]
  }
}
# allow for domain join & reboot (by Azure Policy)
resource "time_sleep" "vm-devops-settle" {
  triggers = {
    subnet_arn = azurerm_windows_virtual_machine.vm-devops.identity[0].principal_id
  }

  create_duration = "5m"
}
# install Azure Storage Explorer && Azure Data Studio
resource "azapi_resource" "vm-devops-install-ase" {

  type = "Microsoft.Compute/virtualMachines/runCommands@2023-03-01"

  name      = "Install-Azure-Storage-Explorer"
  parent_id = azurerm_windows_virtual_machine.vm-devops.id
  # location must be provided as part of the 'body' (ARM schema validation said so...)
  # location = azurerm_windows_virtual_machine.vm-devops.location
  body = jsonencode(
    {
      # location must match vnet's
      location = azurerm_windows_virtual_machine.vm-devops.location
      properties = {
        asyncExecution      = false,
        parameters          = [],
        protectedParameters = [],
        source = {
          script = file(".\\command_install_azure_storage_explorer.ps1")
        }
      }
    }
  )
  tags = azurerm_windows_virtual_machine.vm-devops.tags

  ignore_casing             = false
  ignore_missing_property   = false
  schema_validation_enabled = true

  response_export_values = [
  ]

  depends_on = [
    time_sleep.vm-devops-settle
  ]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
resource "azapi_resource" "vm-devops-install-ads" {

  type = "Microsoft.Compute/virtualMachines/runCommands@2023-03-01"

  name      = "Install-Azure-Data-Studio"
  parent_id = azurerm_windows_virtual_machine.vm-devops.id
  # location must be provided as part of the 'body' (ARM schema validation said so...)
  # location = azurerm_windows_virtual_machine.vm-devops.location
  body = jsonencode(
    {
      # location must match vnet's
      location = azurerm_windows_virtual_machine.vm-devops.location
      properties = {
        asyncExecution      = false,
        parameters          = [],
        protectedParameters = [],
        source = {
          script = file(".\\command_install_azure_data_studio.ps1")

        }
      }
    }
  )
  tags = azurerm_windows_virtual_machine.vm-devops.tags

  ignore_casing             = false
  ignore_missing_property   = false
  schema_validation_enabled = true

  response_export_values = [
  ]

  depends_on = [
    azapi_resource.vm-devops-install-ase
  ]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

output "vm-devops-install-ase" {
  value = azapi_resource.vm-devops-install-ase.id
}
output "vm-devops-install-ads" {
  value = azapi_resource.vm-devops-install-ads.id
}
