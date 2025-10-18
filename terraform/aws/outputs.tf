output "public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.node_exporter.public_ip
}
