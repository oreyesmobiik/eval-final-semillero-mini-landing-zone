data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  lower   = true
  numeric = true
  special = false
}

locals {
  suffix = random_string.suffix.result

  base_name = lower("${var.prefix}-${var.environment}-${local.suffix}")

  tags = {
    environment = var.environment
    owner       = var.owner
    managedBy   = "terraform"
    platform    = "landing-zone-mini"
  }
}

resource "azurerm_resource_group" "platform" {
  name     = "rg-${local.base_name}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_user_assigned_identity" "gha_infra" {
  name                = "uami-${local.base_name}-infra"
  location            = var.location
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags
}

resource "azurerm_user_assigned_identity" "gha_app" {
  name                = "uami-${local.base_name}-app"
  location            = var.location
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "infra_pr" {
  name                      = "fic-${local.base_name}-infra-pr"
  user_assigned_identity_id = azurerm_user_assigned_identity.gha_infra.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${var.github_org}/${var.github_repo}:pull_request"
}

resource "azurerm_federated_identity_credential" "infra_main" {
  name                      = "fic-${local.base_name}-infra-main"
  user_assigned_identity_id = azurerm_user_assigned_identity.gha_infra.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_default_branch}"
}

resource "azurerm_federated_identity_credential" "app_main" {
  name                      = "fic-${local.base_name}-app-main"
  user_assigned_identity_id = azurerm_user_assigned_identity.gha_app.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_default_branch}"
}

module "network" {
  source = "./modules/network"

  resource_group_name                = azurerm_resource_group.platform.name
  location                           = var.location
  hub_vnet_name                      = "vnet-hub-${local.base_name}"
  hub_vnet_cidr                      = var.hub_vnet_cidr
  hub_gateway_subnet_cidr            = var.hub_gateway_subnet_cidr
  enable_bastion_subnet              = var.enable_bastion_subnet
  hub_bastion_subnet_cidr            = var.hub_bastion_subnet_cidr
  spoke_vnet_name                    = "vnet-spoke-${local.base_name}"
  spoke_vnet_cidr                    = var.spoke_vnet_cidr
  spoke_aks_subnet_cidr              = var.spoke_aks_subnet_cidr
  spoke_private_endpoint_subnet_cidr = var.spoke_private_endpoint_subnet_cidr
  private_dns_zone_acr_name          = "privatelink.azurecr.io"
  private_dns_zone_keyvault_name     = "privatelink.vaultcore.azure.net"
  tags                               = local.tags
}

module "acr" {
  source = "./modules/acr"

  resource_group_name     = azurerm_resource_group.platform.name
  location                = var.location
  name                    = substr(replace("acr${local.base_name}", "-", ""), 0, 50)
  private_endpoint_subnet = module.network.private_endpoint_subnet_id
  private_dns_zone_id     = module.network.private_dns_zone_acr_id
  tags                    = local.tags
}

module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name     = azurerm_resource_group.platform.name
  location                = var.location
  name                    = substr(replace("kv-${local.base_name}", "_", "-"), 0, 24)
  tenant_id               = data.azurerm_client_config.current.tenant_id
  private_endpoint_subnet = module.network.private_endpoint_subnet_id
  private_dns_zone_id     = module.network.private_dns_zone_keyvault_id
  tags                    = local.tags
}

module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.platform.name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  name                = "aks-${local.base_name}"
  dns_prefix          = "aks-${local.suffix}"
  subnet_id           = module.network.aks_subnet_id
  acr_id              = module.acr.id
  tags                = local.tags
}

module "policy" {
  source = "./modules/policy"

  scope_resource_group_id = azurerm_resource_group.platform.id
  location                = var.location
  tags                    = local.tags
}

module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name   = azurerm_resource_group.platform.name
  location              = var.location
  aks_id                = module.aks.id
  aks_name              = module.aks.name
  keyvault_id           = module.keyvault.id
  aks_nsg_id            = module.network.aks_nsg_id
  private_endpoint_nsg_id = module.network.private_endpoint_nsg_id
  app_namespace         = var.app_namespace
  cpu_threshold_percent = var.aks_node_cpu_alert_threshold
  alert_email_receiver  = var.monitor_alert_email_receiver
  tags                  = local.tags
}

resource "azurerm_role_assignment" "infra_contributor_rg" {
  scope                = azurerm_resource_group.platform.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.gha_infra.principal_id
}

resource "azurerm_role_assignment" "app_acr_push" {
  scope                = module.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.gha_app.principal_id
}

resource "azurerm_role_assignment" "app_aks_user" {
  scope                = module.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azurerm_user_assigned_identity.gha_app.principal_id
}

resource "azurerm_role_assignment" "app_aks_writer" {
  scope                = module.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  principal_id         = azurerm_user_assigned_identity.gha_app.principal_id
}

resource "azurerm_role_assignment" "aks_kubelet_keyvault_secrets_user" {
  scope                = module.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.aks.kubelet_object_id
}
