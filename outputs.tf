# ── Subnet Group ──────────────────────────────────────────
output "subnet_group_name" {
  value = aws_db_subnet_group.this.name
}

# ── Security Group ────────────────────────────────────────
output "sg_id" {
  value = aws_security_group.this.id
}

# ── RDS Instance ──────────────────────────────────────────
output "rds_identifier" {
  value = aws_db_instance.this.identifier
}

output "endpoint" {
  value = aws_db_instance.this.endpoint
}

output "port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "maintenance_window" {
  value = aws_db_instance.this.maintenance_window
}

output "backup_window" {
  value = aws_db_instance.this.backup_window
}

output "backup_retention_period" {
  value = aws_db_instance.this.backup_retention_period
}