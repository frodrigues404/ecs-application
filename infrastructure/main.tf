# Deploy VPC
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/5.8.1

module "vpc-dogs-app" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${local.project}-${local.environment}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = local.tags
}

# Deploy ECR
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository

resource "aws_ecr_repository" "dogs-app" {
  name                 = "${local.project}-${local.environment}-dogs-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

# Deploy Application Load Balancer
# https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/9.9.0

resource "aws_lb" "application_load_balancer" {
  name               = "${local.project}-${local.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = module.vpc-dogs-app.public_subnets

  enable_deletion_protection = false

  tags = local.tags
}

resource "aws_lb_target_group" "dog_app_target_group" {
  name     = "${local.project}-${local.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc-dogs-app.vpc_id
  health_check {
    port     = 80
    protocol = "HTTP"
    path = "/healthcheck"
  }
}

resource "aws_lb_listener" "dog_app_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dog_app_target_group.arn
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = module.vpc-dogs-app.vpc_id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}