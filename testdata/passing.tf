# SOC2 Audit-Ready Terraform Configuration
# This file implements SOC2 Trust Service Criteria controls
# Note: Passing Kiln scans does not guarantee SOC2 compliance

# =============================================================================
# S3 Bucket with SOC2 Control Implementation
# =============================================================================

resource "aws_s3_bucket" "example" {
  bucket = "audit-ready-bucket"
  
  tags = {
    Environment = "production"
    Owner       = "security-team"
    Purpose     = "example-storage"
  }
}

# CC6.6 - Encryption at Rest
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CC6.1 - Public Access Controls
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CC7.1 & CC8.1 - Versioning for Availability and Change Tracking
resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# CC7.2 - Access Logging
resource "aws_s3_bucket" "logs" {
  bucket = "example-log-bucket"
  
  tags = {
    Environment = "production"
    Owner       = "security-team"
    Purpose     = "logs"
  }
}

resource "aws_s3_bucket_logging" "example" {
  bucket = aws_s3_bucket.example.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}

# CC6.7 - HTTPS Enforcement (optional but recommended)
resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.example.arn,
          "${aws_s3_bucket.example.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# =============================================================================
# CloudTrail - Required for CC7.2
# =============================================================================

resource "aws_cloudtrail" "main" {
  name                          = "main-audit-trail"
  s3_bucket_name                = aws_s3_bucket.logs.id
  enable_logging                = true
  is_multi_region_trail         = true
  include_global_service_events = true

  tags = {
    Environment = "production"
    Owner       = "security-team"
  }
}

# =============================================================================
# RDS Instance - Implements SOC2 Controls
# =============================================================================

resource "aws_db_instance" "example" {
  identifier              = "example-database"
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "14.7"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "changeme123"  # Use secrets manager in production!
  
  # CC6.6 - Encryption at Rest
  storage_encrypted       = true
  
  # CC7.1 - Availability
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  multi_az                = true
  
  # Prevent accidental deletion
  deletion_protection     = true
  skip_final_snapshot     = false
  final_snapshot_identifier = "example-db-final-snapshot"
  
  tags = {
    Environment = "production"
    Owner       = "data-team"
    Purpose     = "production-database"
  }
}

# =============================================================================
# VPC with Flow Logs - CC7.2
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Environment = "production"
    Owner       = "network-team"
  }
}

resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn

  tags = {
    Environment = "production"
    Owner       = "network-team"
  }
}

# Supporting resources for flow logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 7

  tags = {
    Environment = "production"
    Owner       = "network-team"
  }
}

resource "aws_iam_role" "flow_logs" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = "production"
    Owner       = "network-team"
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# =============================================================================
# Security Group - Properly Configured (CC6.1)
# =============================================================================

resource "aws_security_group" "app" {
  name        = "app-security-group"
  description = "Security group with restricted access"
  vpc_id      = aws_vpc.main.id

  # Only allow SSH from corporate network
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Restricted to private network
    description = "SSH from corporate network"
  }

  # Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Environment = "production"
    Owner       = "security-team"
  }
}

# =============================================================================
# Load Balancer - HTTPS Only (CC6.7)
# =============================================================================

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Environment = "production"
    Owner       = "network-team"
  }
}

resource "aws_lb" "main" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app.id]
  subnets            = [aws_subnet.public.id]

  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}

# =============================================================================
# IMPORTANT NOTES
# =============================================================================
#
# This file demonstrates infrastructure that implements SOC2 Trust Service 
# Criteria controls. It should pass Kiln scans with minimal to no issues.
#
# However, passing Kiln scans does NOT mean:
# - Your infrastructure is "SOC2 compliant"
# - You will pass a SOC2 audit
# - You don't need a formal audit by a licensed CPA
#
# SOC2 compliance requires:
# - Formal audit by AICPA-accredited CPA firm
# - Organizational policies and procedures
# - Demonstrated operation of controls over time (6-12 months)
# - Management documentation and representations
#
# This file is for testing and demonstration purposes only.
# =============================================================================

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }

  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}

# Redirect HTTP to HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
