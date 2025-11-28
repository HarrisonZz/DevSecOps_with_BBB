provider "aws" {
  region  = "ap-northeast-2"
  profile = "admin"
}

module "lambda_iot" {
  source = "./modules/lambda_iot"
}

module "api_gateway" {
  source            = "./modules/api_gateway"
  lambda_invoke_arn = module.lambda_iot.lambda_invoke_arn
  lambda_name       = module.lambda_iot.lambda_name
}

module "network" {
  source = "./modules/network"

  vpc_cidr      = "10.0.0.0/16"
  vpc_name      = "aurora-vpc"
  public_a_cidr = "10.0.0.0/24"
  public_a_az   = "ap-northeast-2a"

  private_a_cidr = "10.0.1.0/24"
  private_a_az   = "ap-northeast-2a"
  private_b_cidr = "10.0.2.0/24"
  private_b_az   = "ap-northeast-2b"
}

module "rds" {
  source = "./modules/rds"

  subnet_ids        = module.network.private_subnet_ids
  db_security_group = module.network.aurora_sg_id
}

module "lambda_db" {
  source = "./modules/lambda_db"

  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.network.lambda_sg_id]

  db_host     = module.rds.endpoint
  db_name     = "web_app_db"
  db_user     = "harrison"
  db_password = "dbpassword"
}

output "api_gateway_url" {
  description = "The full invoke URL for HTTP API"
  value       = module.api_gateway.invoke_gateway_url
}
