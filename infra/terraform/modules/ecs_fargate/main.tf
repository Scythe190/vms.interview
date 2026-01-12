locals {
  name_prefix           = "${var.app_name}-${var.environment}"
  ecr_repository_name   = var.ecr_repository_name != "" ? var.ecr_repository_name : local.name_prefix
  alb_name              = substr("${local.name_prefix}-alb", 0, 32)
  target_group_name     = substr("${local.name_prefix}-tg", 0, 32)
  cluster_name          = "${local.name_prefix}-cluster"
  log_group_name        = "/ecs/${local.name_prefix}"
  task_execution_role   = "${local.name_prefix}-task-exec"
  task_role_name        = "${local.name_prefix}-task"
  db_azs                = slice(var.azs, 0, length(var.db_subnet_cidrs))
  db_connection_string  = "Host=${aws_db_instance.this.address};Port=${var.db_port};Database=${var.db_name};Username=${var.db_username};Password=${var.db_password}"
  tags = merge(var.tags, {
    App         = var.app_name
    Environment = var.environment
  })
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = local.tags
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = local.tags
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags                    = local.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = local.tags
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "db" {
  count             = length(var.db_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = local.db_azs[count.index]
  tags              = local.tags
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id
  tags   = local.tags
}

resource "aws_route_table_association" "db" {
  count          = length(aws_subnet.db)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group" "tasks" {
  name        = "${local.name_prefix}-tasks-sg"
  description = "ECS tasks security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "RDS security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = aws_subnet.db[*].id
  tags       = local.tags
}

resource "aws_db_instance" "this" {
  identifier                  = "${local.name_prefix}-db"
  engine                      = var.db_engine
  engine_version              = var.db_engine_version
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  db_name                     = var.db_name
  username                    = var.db_username
  password                    = var.db_password
  port                        = var.db_port
  multi_az                    = var.db_multi_az
  backup_retention_period     = var.db_backup_retention_days
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [aws_security_group.db.id]
  storage_encrypted           = true
  publicly_accessible         = var.db_publicly_accessible
  skip_final_snapshot         = var.db_skip_final_snapshot
  deletion_protection         = var.db_deletion_protection
  apply_immediately           = true
  auto_minor_version_upgrade  = true

  tags = local.tags
}

resource "aws_secretsmanager_secret" "db_connection" {
  name = "${local.name_prefix}-db-connection"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "db_connection" {
  secret_id     = aws_secretsmanager_secret.db_connection.id
  secret_string = local.db_connection_string
}

resource "aws_lb" "this" {
  name               = local.alb_name
  load_balancer_type = "application"
  internal           = false
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.alb.id]
  tags               = local.tags
}

resource "aws_lb_target_group" "this" {
  name        = local.target_group_name
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
  }

  tags = local.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_ecr_repository" "this" {
  name                 = local.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days
  tags              = local.tags
}

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = local.task_execution_role
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "task_execution_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.db_connection.arn]
  }
}

resource "aws_iam_role_policy" "task_execution_secrets" {
  name   = "${local.name_prefix}-task-secrets"
  role   = aws_iam_role.task_execution.name
  policy = data.aws_iam_policy_document.task_execution_secrets.json
}

resource "aws_iam_role" "task" {
  name               = local.task_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = local.tags
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = local.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "${aws_ecr_repository.this.repository_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = var.aspnetcore_environment
        }
      ]
      secrets = [
        {
          name      = "ConnectionStrings__Default"
          valueFrom = aws_secretsmanager_secret.db_connection.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    subnets         = aws_subnet.public[*].id
    security_groups = [aws_security_group.tasks.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  health_check_grace_period_seconds = 30

  depends_on = [aws_lb_listener.http]

  tags = local.tags
}
