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

variable "aks_subnet_name" {
  type = string
}

variable "aks_subnet_cidr" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
