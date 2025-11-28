############################################################
# IAM Role for Lambda
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

  # 建議拿掉 create_before_destroy，避免 name 衝突
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

############################################################
# Lambda Function
############################################################
resource "aws_lambda_function" "write_to_aurora" {
  function_name = var.function_name
  filename      = var.lambda_zip
  handler       = var.handler
  runtime       = var.runtime
  role          = aws_iam_role.lambda_role.arn
  layers        = var.layer_arns

  environment {
    variables = {
      DB_HOST     = var.db_host
      DB_NAME     = var.db_name
      DB_USER     = var.db_user
      DB_PASSWORD = var.db_password
    }
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
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
# EventBridge Rule (schedule Lambda)
############################################################
resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "lambda-cron-rule"
  description         = "Trigger Lambda function every 5 minutes"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "write-to-aurora"
  arn       = aws_lambda_function.write_to_aurora.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.write_to_aurora.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}
