terraform {
    required_providers {
          aws = {
                  source  = "hashicorp/aws"
                  version = ">= 4.14.0, < 5.0.0"  # Compatible version range
          }
    }
}

provider "aws" {
    region  = "eu-central-1"
}