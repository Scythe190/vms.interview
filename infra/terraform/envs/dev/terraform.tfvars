region                 = "eu-west-1"
environment            = "dev"
app_name               = "vms-interview"
vpc_cidr               = "10.0.0.0/16"
public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
db_subnet_cidrs         = ["10.0.101.0/24", "10.0.102.0/24"]
container_port         = 8080
health_check_path      = "/health"
db_name                = "vms"
db_username            = "vmsadmin"
db_instance_class      = "db.t3.micro"
db_allocated_storage   = 20
task_cpu               = 256
task_memory            = 512
desired_count          = 1
image_tag              = "latest"
aspnetcore_environment = "Development"

# Provide the database password via environment variable:
#   $env:TF_VAR_db_password = "your-strong-password"
