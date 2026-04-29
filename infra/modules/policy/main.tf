resource "azurerm_policy_definition" "deny_public_ip" {
  name         = "deny-public-ip-mini-lz"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Deny Public IP resources"

  metadata = jsonencode({
    category = "Network"
  })

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Network/publicIPAddresses"
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_policy_definition" "deny_public_access_for_core_services" {
  name         = "deny-public-access-core-services-mini-lz"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Deny public network access on ACR and Key Vault"

  metadata = jsonencode({
    category = "Security"
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.ContainerRegistry/registries"
            },
            {
              field  = "Microsoft.ContainerRegistry/registries/publicNetworkAccess"
              equals = "Enabled"
            }
          ]
        },
        {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.KeyVault/vaults"
            },
            {
              field  = "Microsoft.KeyVault/vaults/publicNetworkAccess"
              equals = "Enabled"
            }
          ]
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "deny_public_ip" {
  name                 = "asg-deny-public-ip"
  resource_group_id    = var.scope_resource_group_id
  policy_definition_id = azurerm_policy_definition.deny_public_ip.id
  location             = var.location
  enforce              = true
}

resource "azurerm_resource_group_policy_assignment" "deny_public_access_core" {
  name                 = "asg-deny-public-access-core"
  resource_group_id    = var.scope_resource_group_id
  policy_definition_id = azurerm_policy_definition.deny_public_access_for_core_services.id
  location             = var.location
  enforce              = true
}
