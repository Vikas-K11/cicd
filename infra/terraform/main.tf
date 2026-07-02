terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Unique suffix for S3 buckets
resource "random_id" "suffix" {
  byte_length = 4
}

# Auto-generated referer secret header value
resource "random_password" "referer_secret" {
  length  = 32
  special = false
}

# Staging S3 Bucket
module "s3_staging" {
  source         = "./modules/s3-site"
  bucket_name    = "${var.project_name}-staging-${random_id.suffix.hex}"
  env            = "staging"
  referer_secret = random_password.referer_secret.result
}

# Prod Blue S3 Bucket
module "s3_prod_blue" {
  source         = "./modules/s3-site"
  bucket_name    = "${var.project_name}-prod-blue-${random_id.suffix.hex}"
  env            = "prod-blue"
  referer_secret = random_password.referer_secret.result
}

# Prod Green S3 Bucket
module "s3_prod_green" {
  source         = "./modules/s3-site"
  bucket_name    = "${var.project_name}-prod-green-${random_id.suffix.hex}"
  env            = "prod-green"
  referer_secret = random_password.referer_secret.result
}

# SSM Parameter to track active blue-green environment color
resource "aws_ssm_parameter" "active_color" {
  name        = "/site/${var.project_name}/prod-active-color"
  type        = "String"
  value       = "blue"
  description = "Tracks the active prod environment color (blue or green)"

  lifecycle {
    ignore_changes = [value]
  }
}
