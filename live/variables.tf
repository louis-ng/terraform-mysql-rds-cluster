variable "region" {
  description = "AWS region to deploy rds service"
  type        = string
}
variable "create_replica" {
  description = "Create a read replica"
  type        = bool
  default     = true
}

variable "allowed_security_groups" {
  description = "A list of Security Group ID's to allow access to."
}

variable "allowed_security_groups_count" {
  description = "The number of Security Groups being added"
  default     = 0
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "rds_secret_name" {
  description = "Name for the rds secrets manager"
  type        = string
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. "
  type        = string
}

variable "master_password" {
  description = "Master DB password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05."
  type        = string
  default     = ""
}

variable "subnets" {
  description = "List of subnet IDs to use"
  type        = list(string)
}