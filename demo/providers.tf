terraform {
  required_version = "~> 1.1.2"

  required_providers {
    aws = {
      version = "~> 4.8.0"
      source  = "hashicorp/aws"
    }
  }
}

# Define provider and self promote (hi mom!)
provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Owner   = "Kyler"
      Twitter = "@KyMidd"
      Website = "Kyler.omg.lol"
    }
  }
}
