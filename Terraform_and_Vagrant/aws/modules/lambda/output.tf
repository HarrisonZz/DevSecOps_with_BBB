output "lambda_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.iot_lambda.arn
}

output "lambda_invoke_arn" {
  description = "The Invoke ARN of the Lambda function (used for API Gateway integration)"
  value       = aws_lambda_function.iot_lambda.invoke_arn
}

output "lambda_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.iot_lambda.function_name
}
