# ── Identity ──────────────────────────────────────────────
variable "env" {
  description = "Environment: dev | qa | prod"
  type        = string
  default     = "dev"
}

variable "org" {
  description = "Organization name"
  type        = string
}

variable "applicationname" {
  description = "Project or application name"
  type        = string
}

# ── Subnet Group ──────────────────────────────────────────
variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

# ── Security Group ────────────────────────────────────────
variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "ingress_rules" {
  description = "List of inbound rules for the security group"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
  }))
  default = []
}

# ── RDS Instance ──────────────────────────────────────────
variable "engine" {
  description = "Database engine type"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.10"
}

variable "instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage size in GB"
  type        = number
  default     = 20
}

variable "publicly_accessible" {
  description = "Whether the DB is publicly accessible"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "username" {
  description = "Master username for the database"
  type        = string
}

variable "password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection on the RDS instance"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot before deletion"
  type        = bool
  default     = true
}

variable "storage_type" {
  description = "Storage type: gp2 | gp3 | io1"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption. If empty, uses AWS managed key"
  type        = string
  default     = ""
}

variable "auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrade"
  type        = bool
  default     = true
}

variable "maintenance_window" {
  description = "Maintenance window (ddd:hh24:mi-ddd:hh24:mi)"
  type        = string
  default     = "sun:09:00-sun:09:30"
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Backup window (hh24:mi-hh24:mi)"
  type        = string
  default     = "10:00-10:30"
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

variable "engine_lifecycle_support" {
  description = "RDS extended support: open-source-rds-extended-support | open-source-rds-extended-support-disabled"
  type        = string
  default     = "open-source-rds-extended-support-disabled"
}

# ── Monitoring ────────────────────────────────────────────
variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds: 0 (disabled), 1, 5, 10, 15, 30, 60"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "database_insights_mode" {
  description = "Database Insights mode: standard | advanced"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "advanced"], var.database_insights_mode)
    error_message = "Must be 'standard' or 'advanced'."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Retention period in days: 7 (free), 31, 62... 731. Advanced mode requires >= 465"
  type        = number
  default     = 7
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Log types to export to CloudWatch: postgresql, upgrade, iam-db-auth-error"
  type        = list(string)
  default     = []
}
