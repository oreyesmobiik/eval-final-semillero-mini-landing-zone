terraform {
  required_version = ">= 1.7.0"

  backend "azurerm" {
    container_name       = "placeholder"
    key                  = "placeholder.tfstate"
    storage_account_name = "placeholder"
    use_azuread_auth     = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.30"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}
