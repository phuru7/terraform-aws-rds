locals {
  prefix = "${var.env}-${var.org}-${var.applicationname}"
}

# ── Subnet Group ──────────────────────────────────────────
resource "aws_db_subnet_group" "this" {
  name       = "${local.prefix}-subnet-group"
  description = "Subnet group for ${var.applicationname} - ${var.env}"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${local.prefix}-subnet-group"
  }
}

# ── Security Group ────────────────────────────────────────
resource "aws_security_group" "this" {
  name   = "${local.prefix}-sg"
  description = "Security group for ${var.applicationname} RDS - ${var.env}"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      security_groups = ingress.value.security_groups
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.prefix}-sg"
  }
}

# ── RDS Instance ──────────────────────────────────────────
resource "aws_db_instance" "this" {
  identifier        = "${local.prefix}-rds"
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.username
  password = var.password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  multi_az            = var.multi_az
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id != "" ? var.kms_key_id : null

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  maintenance_window         = var.maintenance_window
  backup_retention_period    = var.backup_retention_period
  backup_window              = var.backup_window
  copy_tags_to_snapshot      = var.copy_tags_to_snapshot
  
  tags = {
    Name        = "${local.prefix}-rds"
  }
}
