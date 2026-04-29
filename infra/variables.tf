variable "prefix" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "contoso"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag value"
  type        = string
  default     = "platform-team"
}

variable "github_org" {
  description = "GitHub organization or user"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_default_branch" {
  description = "Default branch for CD"
  type        = string
  default     = "main"
}

variable "vnet_cidr" {
  description = "Address space for virtual network"
  type        = string
  default     = "10.50.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "Subnet CIDR for AKS nodes"
  type        = string
  default     = "10.50.1.0/24"
}

variable "private_endpoint_subnet_cidr" {
  description = "Subnet CIDR for private endpoints"
  type        = string
  default     = "10.50.2.0/24"
}
