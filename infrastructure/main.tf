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

# Deploy ACM
# https://registry.terraform.io/modules/terraform-aws-modules/acm/aws/5.0.1

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.0.1"

  domain_name  = "my-domain.com"
  zone_id      = "Z2ES7B9AZ6SHAE"

  validation_method = "DNS"

  subject_alternative_names = [
    "*.my-domain.com",
    "app.sub.my-domain.com",
  ]

  wait_for_validation = true

  tags = {
    Name = "my-domain.com"
  }
}

# Deploy Application Load Balancer
# https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/9.9.0

module "alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "9.9.0"

  name    = "${local.project}-${local.environment}-alb"
  vpc_id  = module.vpc-dogs-app.vpc_id
  subnets = module.vpc-dogs-app.public_subnets

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"

      forward = {
        target_group_key = "ex-instance"
      }
    }
  }

  target_groups = {
    dogs-tg = {
      name_prefix      = "dog"
      protocol         = "HTTP"
      port             = 80
      target_type      = "ip"
    }
  }

  tags = local.tags
}