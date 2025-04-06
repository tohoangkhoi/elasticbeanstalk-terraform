variable "aws_region" {
  default = "ap-southeast-2"
}

variable "domain_name" {
  default = "YOUR_DOMAIN_NAME"
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

//The zip file of the application, need to be placed in the same directory
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
  default = "YOUR_CERTIFICATE_ARN"
}

//Use this for go_daddy
resource "aws_acm_certificate" "godaddy_cert" {
  private_key       = file("private.key")
  certificate_body  = file("certificate.crt")
  certificate_chain = file("ca_bundle.crt")
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
  db_subnet_group_name = "YOUR_SUBNET_GROUP_NAME"
  db_cluster_name      = "YOUR_DB_CLUSTER_NAME"
  db_username          = "YOUR_DB_USER_NAME"
  db_password          = "YOUR_DB_PASSWORD"
  db_name              = "YOUR_DB_NAME"
  kms_key_id           = "YOUR_KMS_KEY_ARN"
}

locals {
  environment_variables = {
    AI_URL                = ""
    AI_X_API_KEY          = ""
    API_ENDPOINT          = ""
    AVERTRO_DATA_TOKEN    = ""
    AVERTRO_DATA_URL      = ""
    AWS_ACCESS_KEY_ID     = "YOUR_AWS_ACCESS_KEY_ID"
    AWS_SECRET_ACCESS_KEY = "YOUR_AWS_SECRET_KEY"
    BASE_URL              = "YOUR_BASE_URL"
    CONNECT_API           = ""
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

