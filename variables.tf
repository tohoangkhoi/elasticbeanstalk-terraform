variable "aws_region" {
  default = "ap-southeast-2"
}

variable "domain_name" {
  default = "api.example.com" # Replace with your custom domain
}

variable "environment_suffix" {
  default = ["dev", "staging", "prod"] # Environments
}

variable "source_code_storage_bucket_name" {
  default = "terraform-av-api"
}

variable "source_code_file_name" {
  default = "avertro-api"
}

variable "application_app_name" {
  default = "avertro-api-app"
}