output "invoke_gateway_url" {
  description = "Full invoke URL for the API Gateway endpoint"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/led"
}
