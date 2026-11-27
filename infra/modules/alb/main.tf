# Application Load Balancer configurable.
#
# Se instancia dos veces:
#   - público:   listeners 80 (ui) y 8081 (admin), abiertos a internet;
#   - interno:   listeners 8082-8085 para catalog, carts, orders y checkout,
#                accesibles solo desde las tareas de la VPC.
#
# Los target groups son de tipo `ip` porque las tareas de Fargate con modo de
# red `awsvpc` se registran por dirección IP, no por instancia.

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_lb" "this" {
  name               = "${local.name_prefix}-${var.name_suffix}"
  internal           = var.internal
  load_balancer_type = "application"

  security_groups = var.security_group_ids
  subnets         = var.subnet_ids

  # No hay certificado ni dominio propio en el laboratorio. En un ambiente real
  # se agrega un listener 443 con un certificado de ACM y se redirige el 80.
  enable_deletion_protection = false

  # Rechaza cabeceras con caracteres inválidos antes de enviarlas al backend.
  drop_invalid_header_fields = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${var.name_suffix}"
  })
}

resource "aws_lb_target_group" "this" {
  for_each = var.listeners

  name        = "${local.name_prefix}-${each.key}"
  port        = each.value.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = each.value.health_check_path
    protocol            = "HTTP"
    matcher             = each.value.health_check_matcher
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${each.key}"
  })
}

resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${each.key}"
  })
}
