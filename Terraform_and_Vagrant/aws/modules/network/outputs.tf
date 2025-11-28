output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public_a.id
}

output "private_subnet_ids" {
  value = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
  ]
}

output "private_route_table_id" {
  value = aws_route_table.private_rt.id
}

output "lambda_sg_id" {
  value = aws_security_group.lambda_sg.id
}

output "aurora_sg_id" {
  value = aws_security_group.aurora_sg.id
}
