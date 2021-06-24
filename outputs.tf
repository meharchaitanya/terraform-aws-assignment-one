output "instance_ip_addr_frontend" {
  value = aws_instance.dev_frontend.public_ip
  description = "IP address of the Front end server provisioned in public subnet to host Static Web App"
}

output "instance_ip_addr_backend" {
  value = aws_instance.dev_backend.private_ip
  }

output "db_password" {
  value       = aws_db_instance.mydb1.password
  description = "The password for logging in to the database."
  sensitive   = true
}
