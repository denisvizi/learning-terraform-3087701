terraform {
    required_providers {
          aws = {
                  source  = "hashicorp/aws"
                  version = ">= 4.14.0, < 6.0"  # Compatible with all modules
          }
    }
}

provider "aws" {
    region  = "eu-central-1"
}

}
          }
    }
}