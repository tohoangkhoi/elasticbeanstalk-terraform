# Fetch AWS Account ID dynamically
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "elb_service_account_policy" {
  statement {

    actions = [
      "s3:PutObject"
    ]

    resources = ["arn:aws:s3:::${aws_s3_bucket.lb_log_storage.id}/AWSLogs/*"]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_elb_service_account.main.arn}"]
    }
  }
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
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "source_code" {
  bucket = aws_s3_bucket.source_code_storage_bucket.id
  key    = var.source_code_file_name
  source = "./avertro_api.zip"
  etag   = filemd5("./avertro_api.zip")
}

resource "aws_s3_bucket" "lb_log_storage" {
  bucket        = var.lb_log_bucket_name
  force_destroy = true
  tags = {
    Name = var.lb_log_bucket_name
  }
}

# Only bucket owner and AWS services can interact with bucket
resource "aws_s3_bucket_public_access_block" "lb_public_access_block" {
  bucket                  = aws_s3_bucket.lb_log_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lb_bucket_configuration" {
  bucket = aws_s3_bucket.lb_log_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Define the S3 Bucket Policy
resource "aws_s3_bucket_policy" "lb_bucket_policy" {
  bucket = aws_s3_bucket.lb_log_storage.id
  policy = data.aws_iam_policy_document.elb_service_account_policy.json
}