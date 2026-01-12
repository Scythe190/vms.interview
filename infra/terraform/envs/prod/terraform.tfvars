region                 = "eu-west-1"
environment            = "prod"
app_name               = "vms-interview"
vpc_cidr               = "10.1.0.0/16"
public_subnet_cidrs     = ["10.1.1.0/24", "10.1.2.0/24"]
db_subnet_cidrs         = ["10.1.101.0/24", "10.1.102.0/24"]
container_port         = 8080
health_check_path      = "/health"
db_name                = "vms"
db_username            = "vmsadmin"
db_instance_class      = "db.t3.small"
db_allocated_storage   = 50
db_multi_az            = true
db_backup_retention_days = 7
db_skip_final_snapshot = false
db_deletion_protection = true
task_cpu               = 512
task_memory            = 1024
desired_count          = 2
image_tag              = "latest"
aspnetcore_environment = "Production"

# Provide the database password via environment variable:
#   $env:TF_VAR_db_password = "your-strong-password"
