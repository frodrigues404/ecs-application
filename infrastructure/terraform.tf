terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.48.0"
    }
  }
  backend "s3" {
    bucket = "fernando.rodrigues-tfstates"
    key    = "examples/ecs-dogs-application/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  # Configuration options
  region = local.region
}