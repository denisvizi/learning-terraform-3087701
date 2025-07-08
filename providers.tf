terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74" # Example: last 3.x version
    }
  }
}

provider "aws" {
  region  = "eu-central-1"
}
