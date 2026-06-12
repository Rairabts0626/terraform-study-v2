variable "nat_enabled" {

  type = bool

  default = false
}

variable "db_password" {

  type      = string

  sensitive = true
}

variable "notification_email" {

  type = string
}
