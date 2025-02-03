# Create an HTTP Listener for port 80 (if it doesn't exist)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.shared_load_balancer.arn # Reference your shared ALB
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = 200
      content_type = "text/plain"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.shared_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.lb_ssl_policy
  certificate_arn   = var.certificate_arn
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Default response"
      status_code  = "404"
    }
  }
}

# Create Target Groups for each environment
resource "aws_lb_target_group" "lb_tg" {
  for_each = toset(var.environment_suffix)

  name        = "${each.key}-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id # Reference your VPC ID
  target_type = "instance"      # Assuming EC2 instances are used in your environment
}

# Create a listener rule for HTTP listener (port 80)
resource "aws_lb_listener_rule" "http_listener_rule" {
  for_each = toset(var.environment_suffix) # Iterate over your environment suffixes

  listener_arn = aws_lb_listener.http_listener.arn
  # Unique priority for each rule

  condition {
    host_header {
      values = ["${each.key}-api.${var.domain_name}"] # Matching the CNAME for each environment
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg[each.key].arn # Forward traffic to the correct target group
  }
}


