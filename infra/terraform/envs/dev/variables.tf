variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "container_port" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "db_subnet_cidrs" {
  type = list(string)
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_engine" {
  type    = string
  default = "postgres"
}

variable "db_engine_version" {
  type    = string
  default = "16.1"
}

variable "db_instance_class" {
  type = string
}

variable "db_allocated_storage" {
  type = number
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "db_backup_retention_days" {
  type    = number
  default = 1
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = true
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}

variable "db_publicly_accessible" {
  type    = bool
  default = false
}

variable "task_cpu" {
  type = number
}

variable "task_memory" {
  type = number
}

variable "desired_count" {
  type = number
}

variable "image_tag" {
  type = string
}

variable "aspnetcore_environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
