output "alb_dns_name" {
  value = module.app.alb_dns_name
}

output "ecr_repository_url" {
  value = module.app.ecr_repository_url
}

output "cluster_name" {
  value = module.app.cluster_name
}

output "service_name" {
  value = module.app.service_name
}

output "db_endpoint" {
  value = module.app.db_endpoint
}

output "db_port" {
  value = module.app.db_port
}

output "db_name" {
  value = module.app.db_name
}

output "db_username" {
  value = module.app.db_username
}

output "db_connection_secret_arn" {
  value = module.app.db_connection_secret_arn
}
