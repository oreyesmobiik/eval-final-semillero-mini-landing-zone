variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "name" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "acr_id" {
  type = string
}

variable "user_node_pool_name" {
  type    = string
  default = "usernp"
}

variable "user_node_pool_vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "user_node_pool_node_count" {
  type    = number
  default = 1
}

variable "tags" {
  type = map(string)
}
