

resource "aws_lb" "shared_load_balancer" {
  name                       = var.lb_name
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.ec2_security_group.id]
  subnets                    = [for subnet in aws_subnet.public : subnet.id]
  enable_deletion_protection = false

  access_logs {
    bucket = aws_s3_bucket.lb_log_storage.id
  }
}



