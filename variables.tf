variable "aws_region" {
  default = "ap-southeast-2"
}

variable "domain_name" {
  default = "khoi-mockapi.com" # Replace with your custom domain
}

variable "hosted_zone_id" {
  default = "Z02755413453VY1T9KYZJ"
}

variable  "vpc_tag_name" {
  default = "terraform-vpc-name"
}

variable "internet_gateway_name" {
  default = "terraform-internet-gateway"
}

variable "environment_suffix" {
  default = ["dev"] # Environments
}

variable "source_code_storage_bucket_name" {
  default = "terraform-av-api"
}

variable "source_code_file_name" {
  default = "avertro-api.zip"
}

variable "application_app_name" {
  default = "avertro-api-app"
}


variable "lb_log_bucket_name" {
  default = "terraform-load-balancer-log-storage"
}

variable "lb_name" {
  default = "terraform-avertro-load-balancer"
}

variable "lb_ssl_policy" {
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "certificate_arn" {
  default = "arn:aws:acm:ap-southeast-2:203918882105:certificate/ec0ed780-b15f-4059-8203-32a18b7f1b2b"
}

variable "lb_target_group_name" {
  default = "terraform-lb-target-group"
}

variable "db_password" {
  default="postgres"
}


locals {
  environment_variables = {
    AI_URL                = ""
    AI_X_API_KEY          = ""
    API_ENDPOINT          = ""
    AVERTRO_DATA_TOKEN    = ""
    AVERTRO_DATA_URL      = ""
    AWS_ACCESS_KEY_ID     = "AKIAS66UDGU4QISCR4N2"
    AWS_SECRET_ACCESS_KEY = "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"
    BASE_URL              = "https://dev.khoi-mockapi.com"
    CONNECT_API           = ""
    DB_HOST               = "db_host"
    DB_NAME               = "db_name"
    DB_PASSWORD           = "${var.db_password}"
    DB_PORT               = "5432"
    DB_USER               = "db_user"
    JWT_SECRET      = "some-string-ideally-uuid"
    MAILGUN_API_KEY = ""
    MAILGUN_DOMAIN  = ""
    REDIS_HOST      = ""
    REDIS_PASSWORD  = ""
    REDIS_PORT      = ""
    REDIS_TYPE      = ""
    TIME_ZONE       = ""
  }
}

