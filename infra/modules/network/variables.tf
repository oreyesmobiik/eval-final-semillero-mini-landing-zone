variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "hub_vnet_name" {
  type = string
}

variable "hub_vnet_cidr" {
  type = string
}

variable "hub_gateway_subnet_cidr" {
  type = string
}

variable "enable_bastion_subnet" {
  type = bool
}

variable "hub_bastion_subnet_cidr" {
  type = string
}

variable "spoke_vnet_name" {
  type = string
}

variable "spoke_vnet_cidr" {
  type = string
}

variable "spoke_aks_subnet_cidr" {
  type = string
}

variable "spoke_private_endpoint_subnet_cidr" {
  type = string
}

variable "private_dns_zone_acr_name" {
  type = string
}

variable "private_dns_zone_keyvault_name" {
  type = string
}

variable "tags" {
  type = map(string)
}
