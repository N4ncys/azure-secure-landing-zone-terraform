resource "azurerm_resource_group" "rg_prod" {
  name     = "rg-prod-network"
  location = "Canada Central"
}

resource "azurerm_virtual_network" "vnet_prod" {
  name                = "vnet-prod-spoke"
  location            = azurerm_resource_group.rg_prod.location
  resource_group_name = azurerm_resource_group.rg_prod.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "snet_app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.rg_prod.name
  virtual_network_name = azurerm_virtual_network.vnet_prod.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "snet_private" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.rg_prod.name
  virtual_network_name = azurerm_virtual_network.vnet_prod.name
  address_prefixes     = ["10.1.2.0/24"]
}




resource "azurerm_network_security_group" "nsg_prod_app" {
  name                = "nsg-prod-app"
  location            = azurerm_resource_group.rg_prod.location
  resource_group_name = azurerm_resource_group.rg_prod.name
}

resource "azurerm_subnet_network_security_group_association" "snet_app_nsg" {
  subnet_id                 = azurerm_subnet.snet_app.id
  network_security_group_id = azurerm_network_security_group.nsg_prod_app.id
}


resource "azurerm_route_table" "rt_prod_app" {
  name                = "rt-prod-app"
  location            = azurerm_resource_group.rg_prod.location
  resource_group_name = azurerm_resource_group.rg_prod.name

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }

  tags = {
    environment = "production"
  }
}


resource "azurerm_subnet_route_table_association" "snet_app_rt" {
  subnet_id      = azurerm_subnet.snet_app.id
  route_table_id = azurerm_route_table.rt_prod_app.id
}


resource "azurerm_log_analytics_workspace" "law_platform" {
  name                = "law-platform"
  location            = "Canada Central"
  resource_group_name = "rg-monitoring"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


resource "azurerm_private_dns_zone" "blob_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "rg-hub-network"
}

resource "azurerm_private_dns_zone" "kv_dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = "rg-hub-network"
}



resource "azurerm_storage_account" "st_prod" {
  name                     = "stprodprivate001111"
  resource_group_name      = azurerm_resource_group.rg_prod.name
  location                 = azurerm_resource_group.rg_prod.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled = false

  tags = {
    environment = "production"
  }
}



resource "azurerm_private_endpoint" "pe_storage" {
  name                = "pe-storage-prod"
  location            = azurerm_resource_group.rg_prod.location
  resource_group_name = azurerm_resource_group.rg_prod.name
  subnet_id           = azurerm_subnet.snet_private.id

  private_service_connection {
    name                           = "psc-storage"
    private_connection_resource_id = azurerm_storage_account.st_prod.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}



resource "azurerm_key_vault" "kv_prod" {
  name                = "kv-prod-secure001"
  location            = azurerm_resource_group.rg_prod.location
  resource_group_name = azurerm_resource_group.rg_prod.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  public_network_access_enabled = false

  tags = {
    environment = "production"
  }
}

data "azurerm_client_config" "current" {}




resource "azurerm_private_endpoint" "pe_kv" {
  name                = "pe-kv-prod"
  location            = azurerm_resource_group.rg_prod.location
  resource_group_name = azurerm_resource_group.rg_prod.name
  subnet_id           = azurerm_subnet.snet_private.id

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = azurerm_key_vault.kv_prod.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}



data "azurerm_resource_group" "rg_hub" {
  provider = azurerm.platform
  name     = "rg-hub-network"
}

data "azurerm_virtual_network" "vnet_hub" {
  provider            = azurerm.platform
  name                = "vnet-hub"
  resource_group_name = data.azurerm_resource_group.rg_hub.name
}




resource "azurerm_bastion_host" "bastion_hub" {
  provider            = azurerm.platform
  name                = "bastion-hub"
  location            = data.azurerm_resource_group.rg_hub.location
  resource_group_name = data.azurerm_resource_group.rg_hub.name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = "${data.azurerm_virtual_network.vnet_hub.id}/subnets/AzureBastionSubnet"
    public_ip_address_id = "/subscriptions/1600c19f-74f6-4dc2-b68d-7533649ec025/resourceGroups/rg-hub-network/providers/Microsoft.Network/publicIPAddresses/pip-bastion-hub"
  }
}



resource "azurerm_firewall" "fw_hub" {
  provider            = azurerm.platform
  name                = "fw-hub"
  location            = data.azurerm_resource_group.rg_hub.location
  resource_group_name = data.azurerm_resource_group.rg_hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  firewall_policy_id = "/subscriptions/1600c19f-74f6-4dc2-b68d-7533649ec025/resourceGroups/rg-hub-network/providers/Microsoft.Network/firewallPolicies/fp-hub"

  ip_configuration {
    name                 = "ipconfig1"
    subnet_id            = "${data.azurerm_virtual_network.vnet_hub.id}/subnets/AzureFirewallSubnet"
    public_ip_address_id = "/subscriptions/1600c19f-74f6-4dc2-b68d-7533649ec025/resourceGroups/rg-hub-network/providers/Microsoft.Network/publicIPAddresses/pip-fw-hub"
  }
}


