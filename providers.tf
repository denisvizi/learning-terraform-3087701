terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Using the latest 5.x version
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}