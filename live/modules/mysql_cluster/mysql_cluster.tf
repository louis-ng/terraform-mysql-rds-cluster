locals {
  final_snapshot_identifier = "${var.final_snapshot_identifier_prefix}-${var.cluster_identifier}-${try(random_id.snapshot_identifier[0].hex, "")}"
}

data "aws_partition" "current" {}

resource "random_id" "snapshot_identifier" {
  count = var.create ? 1 : 0

  keepers = {
    id = var.cluster_identifier
  }

  byte_length = 4
}

resource "aws_rds_cluster" "this" {
  count = var.create ? 1 : 0

  cluster_identifier = var.cluster_identifier

  engine                    = var.engine
  engine_version            = var.engine_version
  db_cluster_instance_class = var.db_cluster_instance_class
  allocated_storage         = var.allocated_storage
  storage_type              = var.storage_type
  storage_encrypted         = var.storage_encrypted
  kms_key_id                = var.kms_key_id

  database_name   = var.database_name
  master_username = var.master_username
  master_password = var.master_password
  port            = "3306"

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  db_subnet_group_name            = var.db_subnet_group_name
  vpc_security_group_ids          = var.vpc_security_group_ids
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this[0].id

  network_type = var.network_type

  iops                         = var.iops
  apply_immediately            = var.apply_immediately
  preferred_maintenance_window = var.preferred_maintenance_window

  snapshot_identifier       = var.snapshot_identifier
  skip_final_snapshot       = false
  final_snapshot_identifier = local.final_snapshot_identifier

  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  deletion_protection = var.deletion_protection

  dynamic "restore_to_point_in_time" {
    for_each = var.restore_to_point_in_time != null ? [var.restore_to_point_in_time] : []

    content {
      restore_to_time = lookup(restore_to_point_in_time.value, "restore_time", null)
      ##source_db_instance_automated_backups_arn = lookup(restore_to_point_in_time.value, "source_db_instance_automated_backups_arn", null)
      source_cluster_identifier = lookup(restore_to_point_in_time.value, "source_db_instance_identifier", null)
      ##source_dbi_resource_id                   = lookup(restore_to_point_in_time.value, "source_dbi_resource_id", null)
      use_latest_restorable_time = lookup(restore_to_point_in_time.value, "use_latest_restorable_time", null)
    }
  }

  dynamic "s3_import" {
    for_each = var.s3_import != null ? [var.s3_import] : []

    content {
      source_engine         = "mysql"
      source_engine_version = s3_import.value.source_engine_version
      bucket_name           = s3_import.value.bucket_name
      bucket_prefix         = lookup(s3_import.value, "bucket_prefix", null)
      ingestion_role        = s3_import.value.ingestion_role
    }
  }

  tags = var.tags

  depends_on = [aws_cloudwatch_log_group.this]

  timeouts {
    create = lookup(var.timeouts, "create", null)
    delete = lookup(var.timeouts, "delete", null)
    update = lookup(var.timeouts, "update", null)
  }
}
