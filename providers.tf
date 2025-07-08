terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      #version = "4.67.0"  # Compatible with all modules
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}