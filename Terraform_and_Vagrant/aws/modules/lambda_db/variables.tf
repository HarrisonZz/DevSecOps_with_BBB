variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type    = string
  default = "web_app_db"
}

variable "db_user" {
  type    = string
  default = "harrison"
}

variable "db_password" {
  type      = string
  default   = "dbpassword" # 之後你可以拿掉 default，改從 tfvars / secret 注入
  sensitive = true
}

variable "function_name" {
  type    = string
  default = "write_to_aurora"
}

variable "lambda_zip" {
  type    = string
  default = "lambda.zip"
}

variable "handler" {
  type    = string
  default = "handler.handler"
}

variable "runtime" {
  type    = string
  default = "python3.11"
}

variable "layer_arns" {
  type = list(string)
  default = [
    "arn:aws:lambda:ap-northeast-2:770693421928:layer:Klayers-p311-requests:20",
  ]
}

variable "schedule_expression" {
  type    = string
  default = "rate(5 minutes)"
}
