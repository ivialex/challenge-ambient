terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
  #   access_key = "AKIAYMSRWIK4ESE7ADMV"
  #   secret_key = "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"
}
