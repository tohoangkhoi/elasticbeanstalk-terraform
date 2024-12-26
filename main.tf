provider "aws" {
  region  = var.aws_region
  profile = "tohoangkhoi-aws-profile"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["elasticbeanstalk.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


locals {
  az_names = data.aws_availability_zones.available.names
}


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"


  tags = {
    Name = "terraform-vpc"
  }
}


# Create subnets for each availability zone using for_each
resource "aws_subnet" "public" {
  for_each = toset(local.az_names)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, index(local.az_names, each.key))
  availability_zone = each.key

  tags = {
    terraform = true
  }
}

# Outputs for verification
output "subnet_ids" {
  value = { for az, subnet in aws_subnet.public : az => subnet.id }
}

resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security groups"
  description = "Security group for ec2 instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "terraform-ec2-security-group"
  }
}

resource "aws_security_group" "lb_security_group" {
  name        = "load balancer security group"
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "terraform-lb-security-group"
  }
}


resource "aws_vpc_security_group_ingress_rule" "inbound_rule_allow_https_ipv4" {
  security_group_id = aws_security_group.ec2_security_group.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}


resource "aws_vpc_security_group_egress_rule" "outbound_rule_allow_https_ipv4" {
  #   security_group_id = aws_security_group.allow_tls.id
  security_group_id = aws_security_group.ec2_security_group.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp" # semantically equivalent to all ports
}

resource "aws_s3_bucket" "source_code_storage_bucket" {
  bucket        = var.source_code_storage_bucket_name
  force_destroy = true

  tags = {
    Name = var.source_code_storage_bucket_name
  }
}


# Only bucket owner and AWS services can interact with bucket
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.source_code_storage_bucket.id
  restrict_public_buckets = true
}

resource "aws_s3_object" "source_code" {
  bucket = var.source_code_storage_bucket_name
  key    = var.source_code_file_name
  source = "./avertro_api.zip"
  etag   = filemd5("./avertro_api.zip")
}

# IAM Role
resource "aws_iam_role" "elastic_beanstalk_role" {
  name               = "terraform_elastic_beanstalk_service_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# Managed Policy for CloudFormation Operations
resource "aws_iam_policy" "cloudformation_operations" {
  name        = "cloudformation_operations"
  description = "Allow CloudFormation operations on Elastic Beanstalk stacks"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudformationOperationsOnElasticBeanstalkStacks"
        Effect = "Allow"
        Action = ["cloudformation:*"]
        Resource = [
          "arn:aws:cloudformation:*:*:stack/awseb-*",
          "arn:aws:cloudformation:*:*:stack/eb-*"
        ]
      }
    ]
  })
}

# Managed Policy for Log Groups
resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "cloudwatch_logs"
  description = "Allow delete operations on CloudWatch log groups"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowDeleteCloudwatchLogGroups"
        Effect   = "Allow"
        Action   = ["logs:DeleteLogGroup"]
        Resource = ["arn:aws:logs:*:*:log-group:/aws/elasticbeanstalk*"]
      }
    ]
  })
}

# Managed Policy for S3 Buckets
resource "aws_iam_policy" "s3_operations" {
  name        = "s3_operations"
  description = "Allow S3 operations on Elastic Beanstalk buckets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3OperationsOnElasticBeanstalkBuckets"
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::elasticbeanstalk-*",
          "arn:aws:s3:::elasticbeanstalk-*/*"
        ]
      }
    ]
  })
}

# Attach Policies to the Role
resource "aws_iam_role_policy_attachment" "cloudformation_attachment" {
  role       = aws_iam_role.elastic_beanstalk_role.name
  policy_arn = aws_iam_policy.cloudformation_operations.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_attachment" {
  role       = aws_iam_role.elastic_beanstalk_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

resource "aws_iam_role_policy_attachment" "s3_attachment" {
  role       = aws_iam_role.elastic_beanstalk_role.name
  policy_arn = aws_iam_policy.s3_operations.arn
}
resource "aws_elastic_beanstalk_application" "avertro-api-app" {
  name = var.application_app_name

  appversion_lifecycle {
    service_role          = aws_iam_role.elastic_beanstalk_role.arn
    max_count             = 128
    delete_source_from_s3 = true
  }
}

resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "tf-avertro-api-app-version"
  application = aws_elastic_beanstalk_application.avertro-api-app.name
  bucket      = aws_s3_bucket.source_code_storage_bucket.id
  key         = aws_s3_object.source_code.id
}


