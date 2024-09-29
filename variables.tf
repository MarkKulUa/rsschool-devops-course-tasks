variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for storing Terraform state"
  type        = string
  default     = "terraform-state-bucket-name-mark-devops"
}

variable "environment" {
  description = "The environment for resources"
  type        = string
  default     = "Dev"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default     = "rsschool-devops-course-tasks"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "MarkKulUa/rsschool-devops-course-tasks"
}
