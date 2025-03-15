variable "aws_region" {
  default = "ap-southeast-2"
}

variable "domain_name" {
  default = "khoi-mockapi.com" # Replace with your custom domain
}

variable "hosted_zone_id" {
  default = "Z02755413453VY1T9KYZJ"
}

variable "vpc_tag_name" {
  default = "tf-vpc-name"
}

variable "internet_gateway_name" {
  default = "tf-internet-gateway"
}

variable "environment_suffix" {
  default = "dev-api" # Environments
}

variable "source_code_storage_bucket_name" {
  default = "tf-av-api"
}

variable "source_code_file_name" {
  default = "avertro-api.zip"
}

variable "application_app_name" {
  default = "avertro-api-app"
}


variable "lb_log_bucket_name" {
  default = "tf-load-balancer-log-storage"
}

variable "lb_name" {
  default = "tf-avertro-load-balancer"
}

variable "lb_ssl_policy" {
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "certificate_arn" {
  default = "arn:aws:acm:ap-southeast-2:203918882105:certificate/ec0ed780-b15f-4059-8203-32a18b7f1b2b"
}

variable "lb_target_group_name" {
  default = "tf-lb-target-group"
}


variable "lb_security_group_name" {
  default = "load balancer security group"
}
variable "eb_security_group_name" {
  default = "ec2 security group"
}

variable "rds_security_group_name" {
  default = "tf-rds-sg"
}



locals {
  db_subnet_group_name = "tf-db-subnet-group"
  db_cluster_name      = "tf-rds-cluster"
  db_username          = "postgres"
  db_password          = "zxnmcmsadksdafjawefasdjkfnjkawef"
  db_name              = "tfdb"
  kms_key_id           = "arn:aws:kms:ap-southeast-2:203918882105:key/1dd00071-f703-4b0d-befa-8bfdaefa27de"
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
    # DB_HOST               = "db_host"
    DB_NAME         = "${local.db_name}"
    DB_PASSWORD     = "${local.db_password}"
    DB_PORT         = "5432"
    DB_USER         = "${local.db_username}"
    JWT_SECRET      = "${local.db_password}"
    MAILGUN_API_KEY = ""
    MAILGUN_DOMAIN  = ""
    REDIS_HOST      = ""
    REDIS_PASSWORD  = ""
    REDIS_PORT      = ""
    REDIS_TYPE      = ""
    TIME_ZONE       = ""
  }
}

