module "lambda" {
  source = "./modules/lambda"
}

module "api_gateway" {
  source            = "./modules/api_gateway"
  lambda_invoke_arn = module.lambda.lambda_invoke_arn
  lambda_name       = module.lambda.lambda_name
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "admin"
}

############################################################
# 1. 基礎網路結構
############################################################
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "aurora-vpc"
  }
}

# 建立 Internet Gateway（給 NAT Gateway 出口）
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "aurora-igw" }
}

# 建立 Public Subnet（放 NAT Gateway）
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = { Name = "public-a" }
}

# Public Route Table（接 Internet Gateway）
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

# 建立 NAT Gateway（Lambda 經此出網）
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id
  tags          = { Name = "aurora-nat" }

  depends_on = [aws_internet_gateway.igw]
}

# 建立 Private Route Table（讓 Lambda 子網可走 NAT）
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "private-rt" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2b"
  tags = {
    Name = "private-b"
  }
}

# 掛上 Lambda 所在的子網
resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}

############################################################
# 2. 安全組
############################################################
resource "aws_security_group" "lambda_sg" {
  name   = "lambda-sg"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-sg"
  }
}

resource "aws_security_group" "aurora_sg" {
  name   = "aurora-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "Allow PostgreSQL from Lambda"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aurora-sg"
  }
}

############################################################
# 3. Aurora Serverless v2
############################################################
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "aurora-serverless-cluster"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = "15.12"
  database_name           = "web_app_db"
  master_username         = "harrison"
  master_password         = "dbpassword"
  vpc_security_group_ids  = [aws_security_group.aurora_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  storage_encrypted       = true
  backup_retention_period = 1
  skip_final_snapshot     = true
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2
  }

  tags = {
    Name = "aurora-serverless"
  }
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name = "aurora-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "aurora-subnet-group"
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier           = "aurora-serverless-instance"
  cluster_identifier   = aws_rds_cluster.aurora_cluster.id
  instance_class       = "db.serverless"
  engine               = "aurora-postgresql"
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  tags = {
    Name = "aurora-serverless-instance"
  }
}

############################################################
# 4. Lambda + IAM Role
############################################################
resource "aws_iam_role" "lambda_role" {
  name = "lambda-rds-writer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_file = "${path.module}/lambda"
#   output_path = "${path.module}/lambda.zip"
# }

resource "aws_lambda_function" "write_to_aurora" {
  function_name = "write_to_aurora"
  filename      = "lambda.zip"      # 上傳好的壓縮包
  handler       = "handler.handler" # Python: lambda_function.lambda_handler
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn
  layers = [
    "arn:aws:lambda:ap-northeast-2:770693421928:layer:Klayers-p311-requests:20"
  ]

  environment {
    variables = {
      DB_HOST     = aws_rds_cluster.aurora_cluster.endpoint
      DB_NAME     = "web_app_db"
      DB_USER     = "harrison"
      DB_PASSWORD = "dbpassword"
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tags = {
    Name = "lambda-write-aurora"
  }
  timeout = 30

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access,
  ]
}

############################################################
# 5. EventBridge Rule (定時觸發 Lambda)
############################################################
resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "lambda-cron-rule"
  description         = "Trigger Lambda function every 5 minutes"
  schedule_expression = "rate(5 minutes)" # 每5分鐘觸發
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "write-to-aurora"
  arn       = aws_lambda_function.write_to_aurora.arn

  depends_on = [
    aws_lambda_function.write_to_aurora
  ]
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.write_to_aurora.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}

output "aurora_endpoint" {
  value = aws_rds_cluster.aurora_cluster.endpoint
}

output "lambda_name" {
  value = aws_lambda_function.write_to_aurora.function_name
}


output "api_gateway_url" {
  description = "The full invoke URL for HTTP API"
  value       = module.api_gateway.invoke_gateway_url
}
