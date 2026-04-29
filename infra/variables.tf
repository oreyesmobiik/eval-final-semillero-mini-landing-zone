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

variable "hub_vnet_cidr" {
  description = "Address space for hub virtual network"
  type        = string
  default     = "10.50.0.0/16"
}

variable "spoke_vnet_cidr" {
  description = "Address space for spoke virtual network"
  type        = string
  default     = "10.51.0.0/16"
}

variable "hub_gateway_subnet_cidr" {
  description = "Subnet CIDR for GatewaySubnet in hub"
  type        = string
  default     = "10.50.0.0/27"
}

variable "enable_bastion_subnet" {
  description = "Whether to create AzureBastionSubnet in hub"
  type        = bool
  default     = false
}

variable "hub_bastion_subnet_cidr" {
  description = "Subnet CIDR for AzureBastionSubnet in hub"
  type        = string
  default     = "10.50.0.32/27"
}

variable "spoke_aks_subnet_cidr" {
  description = "Subnet CIDR for AKS nodes in spoke"
  type        = string
  default     = "10.51.1.0/24"
}

variable "spoke_private_endpoint_subnet_cidr" {
  description = "Subnet CIDR for private endpoints in spoke"
  type        = string
  default     = "10.51.2.0/24"
}

variable "aks_node_cpu_alert_threshold" {
  description = "Alert threshold for AKS node CPU percentage"
  type        = number
  default     = 80
}

variable "app_namespace" {
  description = "Kubernetes namespace for application logs"
  type        = string
  default     = "miniapp"
}

variable "monitor_alert_email_receiver" {
  description = "Optional email receiver for monitor action group alerts"
  type        = string
  default     = null
  nullable    = true
}
