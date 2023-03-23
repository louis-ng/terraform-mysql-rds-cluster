data "aws_availability_zones" "available" {}

locals {
  name = "mysql-service-demo"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name = local.name
  }

  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t4g.large"
  allocated_storage     = 20
  max_allocated_storage = 100
  port                  = 3306
}

resource "random_password" "master" {
  length           = 8
  special          = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "password" {
  name       = var.rds_secret_name
  kms_key_id = var.kms_key_id
}

resource "aws_secretsmanager_secret_version" "password" {
  secret_id     = aws_secretsmanager_secret.password.id
  secret_string = random_password.master.result
}

resource "aws_security_group" "this" {
  name_prefix = "${local.name}-"
  vpc_id      = var.vpc_id

  tags = var.tags
}
resource "aws_security_group_rule" "ingress" {
  count = var.allowed_security_groups_count

  type                     = "ingress"
  from_port                = "3306"
  to_port                  = "3306"
  protocol                 = "tcp"
  source_security_group_id = element(var.allowed_security_groups, count.index)
  security_group_id        = aws_security_group.this.id
}

resource "aws_db_subnet_group" "this" {
  name        = local.name
  description = "For MySql RDS cluster ${local.name}"
  subnet_ids  = var.subnets

  tags = var.tags
}

module "mysql_cluster" {
  source = "../modules/mysql_cluster"

  cluster_identifier = local.name

  engine         = "mysql"
  engine_version = "8.0.28"

  db_cluster_instance_class = "db.m5d.2xlarge"

  allocated_storage = 400
  iops              = 3000
  storage_type      = "io1"

  database_name   = "techDemo"
  master_username = "demoAdmin"
  master_password = (var.snapshot_identifier != "") ? null : (var.master_password == "" ? aws_secretsmanager_secret.password.id : var.master_password)

  snapshot_identifier = ""

  parameter_group_name = local.name

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  preferred_maintenance_window    = "Mon:04:00-Mon:05:00"
  preferred_backup_window         = "02:00-03:00"
  enabled_cloudwatch_logs_exports = ["audit", "error", "general"]


  backup_retention_period = 7
  deletion_protection     = true

}

################################################################################
# Replica DB
################################################################################

module "replica" {
  count = var.create_replica ? 1 : 0

  source = "../modules/mysql_instance"

  identifier = "${local.name}-replica"

  replicate_source_db = module.mysql_cluster.db_instance_id

  engine         = local.engine
  engine_version = local.engine_version
  instance_class = local.instance_class

  allocated_storage     = local.allocated_storage
  max_allocated_storage = local.max_allocated_storage

  port = local.port

  multi_az               = false
  vpc_security_group_ids = [aws_security_group.this.id]

  maintenance_window              = "Tue:00:00-Tue:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["general"]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = local.tags
}
