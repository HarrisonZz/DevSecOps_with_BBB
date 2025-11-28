resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "aurora-subnet-group"
  }
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier = "aurora-serverless-cluster"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "15.12"

  database_name   = var.db_name
  master_username = var.master_username
  master_password = var.master_password

  vpc_security_group_ids  = [var.db_security_group]
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
