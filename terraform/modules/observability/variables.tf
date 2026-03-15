variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "log_analytics_workspace_name" {
  type = string
}

variable "log_retention_days" {
  type = number
}

variable "action_group_name" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
