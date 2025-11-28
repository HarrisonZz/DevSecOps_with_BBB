variable "subnet_ids" {
  type = list(string)
}

variable "db_security_group" {
  type = string
}

variable "db_name" {
  type    = string
  default = "web_app_db"
}

variable "master_username" {
  type    = string
  default = "harrison"
}

variable "master_password" {
  type      = string
  default   = "dbpassword" # 先保持行為一樣，之後你可以拿掉 default 改用 tfvars/SecretManager
  sensitive = true
}
