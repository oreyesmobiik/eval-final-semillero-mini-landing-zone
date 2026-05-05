resource "azurerm_key_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = true
  public_network_access_enabled = false
  rbac_authorization_enabled    = true
  tags                          = var.tags
}

resource "random_password" "miniapp_config" {
  length  = 20
  special = true
}

resource "azurerm_key_vault_secret" "miniapp_config" {
  name         = "miniapp-config"
  value        = random_password.miniapp_config.result
  key_vault_id = azurerm_key_vault.this.id
  content_type = "text/plain"
  tags         = var.tags
}

resource "azurerm_private_endpoint" "this" {
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnsz-kv"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
