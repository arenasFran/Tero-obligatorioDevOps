# Servicio de ECS Fargate reutilizable.
#
# Crea, para un microservicio:
#   - su grupo de logs en CloudWatch;
#   - su registro en Cloud Map (nombre DNS interno);
#   - la task definition con variables y secretos;
#   - el servicio de ECS, opcionalmente conectado a un target group del ALB.
#
# No crea el security group ni la red: los recibe del módulo stack, para que
# todos los servicios compartan las mismas reglas.

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

data "aws_region" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"

  environment = [
    for name, value in var.environment_variables : {
      name  = name
      value = value
    }
  ]

  secrets = [
    for name, value_from in var.secrets : {
      name      = name
      valueFrom = value_from
    }
  ]
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.name_prefix}/${var.service_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${var.service_name}"
  })
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name_prefix}-${var.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = local.environment
      secrets     = local.secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${var.service_name}"
  })
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn == null ? [] : [var.target_group_arn]

    content {
      target_group_arn = load_balancer.value
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  health_check_grace_period_seconds = var.target_group_arn == null ? null : var.health_check_grace_period

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${var.service_name}"
  })
}
