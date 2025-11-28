variable "source_file" {
  type    = string
  default = "lambda_program/handler.py"
}

variable "function_name" {
  type    = string
  default = "BBBIoTCorePost"
}

variable "iot_endpoint" {
  type    = string
  default = "https://a2jf76kc2clrd8-ats.iot.ap-northeast-2.amazonaws.com"
}
