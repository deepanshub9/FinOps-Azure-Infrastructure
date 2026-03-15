variable "prefix" {
  type    = string
  default = "realuse"
}

variable "location" {
  type    = string
  default = "francecentral"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "kubernetes_version" {
  type    = string
  default = "1.35"
}

variable "node_vm_size" {
  type    = string
  default = "Standard_B2s_v2"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "max_pods" {
  type    = number
  default = 50
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "budget_amount_usd" {
  type    = number
  default = 15
}

variable "budget_alert_email" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {
    project     = "real-usecase"
    environment = "dev"
    owner       = "learning"
    ttl         = "ephemeral"
  }
}
