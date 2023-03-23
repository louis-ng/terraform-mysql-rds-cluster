data "aws_rds_engine_version" "family" {
  engine   = var.engine
  version  = var.engine_version
}

resource "aws_rds_cluster_parameter_group" "this" {
  count = var.create ? 1 : 0

  name        = var.parameter_group_name
  description = "${var.cluster_identifier} parameter group"
  family      = data.aws_rds_engine_version.family.parameter_group_family

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}