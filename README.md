# terraform-aws-rds

Terraform module to provision an **AWS RDS PostgreSQL** instance with Security Group, Subnet Group, Enhanced Monitoring, Performance Insights, and CloudWatch Log Exports.

---

## Architecture

```
┌─────────────────────────────────────────┐
│                  VPC                    │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │         Security Group           │   │
│  │    {env}-{org}-{app}-rds-sg      │   │
│  │    Dynamic ingress rules         │   │
│  │    Egress: all traffic allowed   │   │
│  └──────────────┬───────────────────┘   │
│                 │                       │
│  ┌──────────────▼───────────────────┐   │
│  │           RDS Instance           │   │
│  │    {env}-{org}-{app}-rds         │   │
│  │    engine: postgres              │   │
│  │    storage: gp3 + encrypted      │   │
│  └──────────────────────────────────┘   │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │         DB Subnet Group          │   │
│  │  {env}-{org}-{app}-subnet-group  │   │
│  │  subnet-a │ subnet-b             │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘

Optional:
  IAM Role → Enhanced Monitoring → CloudWatch
```

---

## Requirements

| Tool         | Version  |
|--------------|----------|
| Terraform    | >= 1.5.0 |
| AWS Provider | ~> 6.35  |

**Prerequisites:**
- Existing VPC with private subnets
- Subnet IDs in at least 2 AZs
- Source Security Group IDs (EKS, Glue, Bastion, etc.)

---

## Usage

### Minimal

```hcl
module "rds" {
  source = "git::https://github.com/your-org/terraform-aws-rds.git?ref=v1.0.0"

  env             = "dev"
  org             = "acme"
  applicationname = "myapp"

  db_name  = "myapp_dev_db"
  username = "dbadmin"
  password = var.db_password

  vpc_id     = "vpc-xxxxxxxxxx"
  subnet_ids = ["subnet-aaa", "subnet-bbb"]
}
```

### Complete (prod)

```hcl
module "rds" {
  source = "git::https://github.com/your-org/terraform-aws-rds.git?ref=v1.0.0"

  # Identity
  env             = "prod"
  org             = "acme"
  applicationname = "myapp"

  # Database
  engine            = "postgres"
  engine_version    = "16.10"
  instance_class    = "db.t3.medium"
  allocated_storage = 100
  storage_type      = "gp3"
  db_name           = "myapp_prod_db"
  username          = "dbadmin"
  password          = var.db_password

  # Network
  vpc_id     = "vpc-xxxxxxxxxx"
  subnet_ids = ["subnet-aaa", "subnet-bbb"]
  ingress_rules = [
    {
      description     = "RDS from Bastion"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      cidr_blocks     = ["10.0.1.0/24"]
      security_groups = []
    },
    {
      description     = "RDS from EKS"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      cidr_blocks     = []
      security_groups = ["sg-xxxxxxxxxx"]
    }
  ]

  # High Availability
  multi_az            = true
  deletion_protection = true
  skip_final_snapshot = false

  # Encryption
  storage_encrypted = true
  kms_key_id        = "arn:aws:kms:us-east-1:123456789:key/xxxx"

  # Backup & Maintenance
  backup_retention_period    = 30
  backup_window              = "03:00-03:30"
  maintenance_window         = "sun:04:00-sun:04:30"
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true

  # Monitoring
  monitoring_interval                   = 10
  database_insights_mode                = "advanced"
  performance_insights_enabled          = true
  performance_insights_retention_period = 465
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade", "iam-db-auth-error"]
}
```

### Consuming outputs from another module

```hcl
resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/myapp/prod/db_endpoint"
  type  = "String"
  value = module.rds.endpoint
}

resource "kubernetes_secret" "db" {
  metadata { name = "db-credentials" }
  data = {
    host     = module.rds.endpoint
    port     = module.rds.port
    database = module.rds.db_name
  }
}
```

---

## Naming Convention

```
{env}-{org}-{applicationname}-{resource}

# Examples:
dev-acme-myapp-rds
dev-acme-myapp-rds-sg
dev-acme-myapp-subnet-group
dev-acme-myapp-rds-monitoring-role
```

---

## Inputs

### Identity

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `env` | Environment: dev \| qa \| prod | `string` | `"dev"` | yes |
| `org` | Organization name | `string` | — | yes |
| `applicationname` | Application name | `string` | — | yes |

### Subnet Group

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `subnet_ids` | List of subnet IDs (min 2 AZs) | `list(string)` | — | yes |

### Security Group

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vpc_id` | VPC ID | `string` | — | yes |
| `ingress_rules` | List of inbound rules (see type below) | `list(object)` | `[]` | no |

**Full type for `ingress_rules`:**

```hcl
list(object({
  description     = string
  from_port       = number
  to_port         = number
  protocol        = string
  cidr_blocks     = optional(list(string), [])
  security_groups = optional(list(string), [])
}))
```

> `cidr_blocks` and `security_groups` are both optional and can be combined in the same rule. At least one must have values.

**Egress:** The Security Group allows all outbound traffic (`0.0.0.0/0`) by default. If you need restricted egress, manage those rules outside the module.

### RDS Instance

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `engine` | Database engine type | `string` | `"postgres"` | no |
| `engine_version` | PostgreSQL engine version | `string` | `"16.10"` | no |
| `instance_class` | RDS instance type | `string` | `"db.t3.micro"` | no |
| `allocated_storage` | Storage size in GB | `number` | `20` | no |
| `storage_type` | Storage type: gp2 \| gp3 \| io1 | `string` | `"gp3"` | no |
| `port` | Database port | `number` | `5432` | no |
| `db_name` | Database name | `string` | — | yes |
| `username` | Master username | `string` | — | yes |
| `password` | Master password | `string` | — | yes |
| `publicly_accessible` | Expose DB to internet | `bool` | `false` | no |
| `multi_az` | Enable Multi-AZ | `bool` | `false` | no |
| `deletion_protection` | Enable deletion protection | `bool` | `true` | no |
| `skip_final_snapshot` | Skip final snapshot on delete | `bool` | `true` | no |
| `engine_lifecycle_support` | Extended support mode | `string` | `"open-source-rds-extended-support-disabled"` | no |

### Encryption

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `storage_encrypted` | Enable storage encryption | `bool` | `true` | no |
| `kms_key_id` | KMS key ARN. Empty = AWS managed key | `string` | `""` | no |

### Backup & Maintenance

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `backup_retention_period` | Backup retention in days | `number` | `7` | no |
| `backup_window` | Backup window (hh24:mi-hh24:mi) | `string` | `"10:00-10:30"` | no |
| `maintenance_window` | Maintenance window | `string` | `"sun:06:00-sun:06:30"` | no |
| `copy_tags_to_snapshot` | Copy tags to snapshots | `bool` | `true` | no |
| `auto_minor_version_upgrade` | Auto minor version upgrade | `bool` | `true` | no |

### Monitoring

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `monitoring_interval` | Enhanced Monitoring interval in seconds: 0, 1, 5, 10, 15, 30, 60 | `number` | `0` | no |
| `database_insights_mode` | Database Insights mode: standard \| advanced | `string` | `"standard"` | no |
| `performance_insights_enabled` | Enable Performance Insights | `bool` | `false` | no |
| `performance_insights_retention_period` | Retention in days. Advanced mode requires >= 465 | `number` | `7` | no |
| `enabled_cloudwatch_logs_exports` | Log types to export: postgresql, upgrade, iam-db-auth-error | `list(string)` | `[]` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| `subnet_group_name` | DB Subnet Group name |
| `sg_id` | Security Group ID |
| `rds_identifier` | RDS instance identifier |
| `endpoint` | RDS connection endpoint |
| `port` | RDS port |
| `db_name` | Database name |
| `maintenance_window` | Maintenance window |
| `backup_window` | Backup window |
| `backup_retention_period` | Backup retention period |

---

## Preconditions (prod enforcement)

The module automatically validates the following in `prod`:

```
✅ deletion_protection must be true
✅ skip_final_snapshot must be false
```

If any condition fails, `terraform plan` returns an error before creating any resources.

---

## Secrets Management

`password` must **never** be hardcoded or committed to version control. Two recommended approaches:

**AWS Secrets Manager (recommended for prod):**
```hcl
data "aws_secretsmanager_secret_version" "db" {
  secret_id = "/myapp/prod/db-password"
}

module "rds" {
  # ...
  password = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["password"]
}
```

**AWS SSM Parameter Store:**
```hcl
data "aws_ssm_parameter" "db_password" {
  name            = "/myapp/prod/db-password"
  with_decryption = true
}

module "rds" {
  # ...
  password = data.aws_ssm_parameter.db_password.value
}
```

---

## Engine Version Upgrade

> ⚠️ Changing `engine_version` may cause downtime. Always run during the maintenance window.

1. Take a manual snapshot before applying:
   ```bash
   aws rds create-db-snapshot \
     --db-instance-identifier prod-acme-myapp-rds \
     --db-snapshot-identifier pre-upgrade-snapshot-$(date +%Y%m%d)
   ```
2. For **major** upgrades (e.g. 15.x → 16.x), `allow_major_version_upgrade = true` is required.
3. Run `terraform plan` and confirm the change is in-place (`~`) not a replacement (`-/+`).
4. Apply during the `maintenance_window`.

---

## Destroy / Offboarding

When `deletion_protection = true` and `skip_final_snapshot = false`, a direct `terraform destroy` will fail. Follow this procedure:

```hcl
# Step 1 — disable protections
deletion_protection = false
skip_final_snapshot = true
```

```bash
# Step 2 — apply the change
terraform apply -target=module.rds

# Step 3 — destroy
terraform destroy -target=module.rds
```

---

## Notes

- `admin` is a reserved word in PostgreSQL — use `dbadmin`, `masteruser`, etc.
- `gp3` is the recommended storage type: 20% cheaper than `gp2` with better baseline performance.
- `database_insights_mode = "advanced"` requires `performance_insights_retention_period >= 465`.
- The `provider` block must not be defined inside the child module — it is inherited from the root module.

---

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for the version history and release notes.

---

## License

MIT