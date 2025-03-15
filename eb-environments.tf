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

# IAM Role
# Can't assign a whole policy of BeanstealkServiceRole to our IAM role via terraform, because it will cause "limit exceed error", 
# therefore we need to break the rules in to 3 small parts
resource "aws_iam_role" "elastic_beanstalk_role" {
  name               = "tf_elastic_beanstalk_service_role"
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

## elastic beanstalk application configurations
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


#Create an IamInstanceProfile or Beanstalk Environment
resource "aws_iam_role" "elastic_beanstalk_ec2_role" {
  name = "tf-elasticbeanstalk-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "beanstalk_ec2_role_policy_attachment" {
  name       = "tf-beanstalk-ec2-policy-attachment"
  roles      = [aws_iam_role.elastic_beanstalk_ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_policy_attachment" "beanstalk_ec2_role_policy_attach" {
  name       = "tf-beanstalk-ec2-policy-attach"
  roles      = [aws_iam_role.elastic_beanstalk_ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_instance_profile" "elastic_beanstalk_instance_profile" {
  name = "tf-elasticbeanstalk-ec2-instance-profile"
  role = aws_iam_role.elastic_beanstalk_ec2_role.name
}

# Elastic Beanstalk Environments
resource "aws_elastic_beanstalk_environment" "env" {
  name                = var.environment_suffix
  application         = aws_elastic_beanstalk_application.avertro-api-app.name
  version_label       = aws_elastic_beanstalk_application_version.app_version.name
  solution_stack_name = "64bit Amazon Linux 2 v4.0.5 running Docker"

  dynamic "setting" {

    for_each = local.environment_variables
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
    }
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOST"
    value     = aws_rds_cluster.db_cluster.endpoint
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }


  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", [for subnet in aws_subnet.public : subnet.id])
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = true
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.elastic_beanstalk_instance_profile.name
  }

  #  assign ec2_sg for ec2 instance of the env
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.ec2_security_group.id
  }

  # This option is to force elastic beanstalk launch the environment using LaunchTemplate, not LaunchConfiguration
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "DisableIMDSv1"
    value     = true
  }


  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = "t3.medium"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerIsShared"
    value     = true
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SharedLoadBalancer"
    value     = aws_lb.shared_load_balancer.arn
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = 1
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = 1
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = true
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = false
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = 1
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "Timeout"
    value     = "1800"
  }

}
