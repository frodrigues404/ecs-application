locals {
  region      = "us-east-1"
  environment = "dev"
  project     = "app-dogs"
  azs         = slice(data.aws_availability_zones.az.names, 0, 4)
  vpc_cidr    = "10.0.0.0/16"

  private_subnets = [
    "10.0.1.0/24", 
    "10.0.2.0/24", 
    "10.0.3.0/24"
  ]
  public_subnets = [
    "10.0.101.0/24", 
    "10.0.102.0/24", 
    "10.0.103.0/24"
  ]

  container_image = "010427274449.dkr.ecr.us-east-1.amazonaws.com/app-dogs-dev-dogs-app:latest"
  container_port = 3000
  container_name = "app-dogs-${local.environment}"
  
  tags = {
    Environment = local.environment
    Project     = local.project
  }
}