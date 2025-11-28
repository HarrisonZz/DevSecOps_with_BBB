output "lambda_name" {
  value = aws_lambda_function.write_to_aurora.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.write_to_aurora.arn
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.write_to_aurora.invoke_arn
}
