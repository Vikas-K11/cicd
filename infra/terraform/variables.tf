variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Name prefix for resources"
  default     = "static-site-cicd"
}

variable "github_org" {
  type        = string
  description = "GitHub Organization or Username"
  default     = "Vikas-K11"
}

variable "github_repo" {
  type        = string
  description = "GitHub Repository Name"
  default     = "cicd"
}
