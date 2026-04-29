variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "vnet_cidr" {
  type = string
}

variable "aks_subnet_cidr" {
  type = string
}

variable "private_endpoint_subnet_cidr" {
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
