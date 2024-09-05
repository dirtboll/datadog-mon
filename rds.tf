resource "random_password" "rds_default" {
  length           = 16
  special          = true
  override_special = "_%-{}+"
}

resource "aws_db_parameter_group" "rds_default" {
  description = "Managed by Terraform"
  family      = "postgres16"
  name        = "default"
  name_prefix = null
  tags        = {}
  tags_all    = {}
  parameter {
    apply_method = "pending-reboot"
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
  }
  parameter {
    apply_method = "pending-reboot"
    name         = "track_activity_query_size"
    value        = "4096"
  }
  parameter {
    apply_method = "pending-reboot"
    name         = "pg_stat_statements.track"
    value        = "ALL"
  }
  parameter {
    apply_method = "pending-reboot"
    name         = "pg_stat_statements.max"
    value        = "10000"
  }
  parameter {
    apply_method = "pending-reboot"
    name         = "pg_stat_statements.track_utility"
    value        = "0"
  }
  parameter {
    apply_method = "pending-reboot"
    name         = "track_io_timing"
    value        = "1"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16.4"
  identifier             = "default"
  instance_class         = "db.t3.micro"
  port                   = 5432
  storage_type           = "gp3"
  publicly_accessible    = true
  username               = "postgres"
  password               = random_password.rds_default.result
  vpc_security_group_ids = data.aws_security_groups.default.ids
  parameter_group_name   = aws_db_parameter_group.rds_default.name
}

