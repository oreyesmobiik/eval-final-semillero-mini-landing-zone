variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "aks_id" {
  type = string
}

variable "aks_name" {
  type = string
}

variable "keyvault_id" {
  type = string
}

variable "aks_nsg_id" {
  type = string
}

variable "private_endpoint_nsg_id" {
  type = string
}

variable "cpu_threshold_percent" {
  type = number
}

variable "app_namespace" {
  type = string
}

variable "app_http_error_threshold" {
  type    = number
  default = 5
}

variable "alert_email_receiver" {
  type     = string
  default  = null
  nullable = true
}

variable "tags" {
  type = map(string)
}
