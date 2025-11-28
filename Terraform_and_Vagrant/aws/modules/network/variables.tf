variable "vpc_cidr" {
  type = string
}

variable "vpc_name" {
  type    = string
  default = "aurora-vpc"
}

variable "public_a_cidr" {
  type = string
}

variable "public_a_az" {
  type = string
}

variable "private_a_cidr" {
  type = string
}

variable "private_a_az" {
  type = string
}

variable "private_b_cidr" {
  type = string
}

variable "private_b_az" {
  type = string
}
