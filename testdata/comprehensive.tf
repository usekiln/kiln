# ============================================================
# Comprehensive SOC2 Test File
# This file intentionally contains violations for all controls
# ============================================================

# ============================================================
# CC6.6 - Encryption at Rest - VIOLATIONS
# ============================================================

# FAIL: S3 bucket without encryption
resource "aws_s3_bucket" "unencrypted_data" {
  bucket = "my-unencrypted-bucket"
  
  tags = {
    Environment = "production"
    Owner       = "security-team"
    Purpose     = "user-data"
  }
}

# FAIL: RDS without encryption
resource "aws_db_instance" "unencrypted_db" {
  identifier          = "mydb-unencrypted"
  allocated_storage   = 20
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  username            = "admin"
  password            = "changeme123"
  skip_final_snapshot = true
  
  # Missing: storage_encrypted = true
  
  tags = {
    Environment = "production"
    Owner       = "data-team"
  }
}

# ============================================================
# CC7.2 - Monitoring & Logging - VIOLATIONS
# ============================================================

# FAIL: No CloudTrail configured (checked at infrastructure level)

# FAIL: S3 bucket without access logging
resource "aws_s3_bucket" "no_logging" {
  bucket = "bucket-without-logging"
  
  # Missing: aws_s3_bucket_logging resource
  
  tags = {
    Environment = "production"
    Owner       = "ops-team"
  }
}

# FAIL: VPC without flow logs
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  # Missing: aws_flow_log resource
  
  tags = {
    Environment = "production"
    Owner       = "network-team"
  }
}

# ============================================================
# CC6.1 - Access Controls - VIOLATIONS
# ============================================================

# FAIL: S3 bucket without public access block
resource "aws_s3_bucket" "public_access" {
  bucket = "potentially-public-bucket"
  
  # Missing: aws_s3_bucket_public_access_block
  
  tags = {
    Environment = "production"
    Owner       = "web-team"
  }
}

# FAIL: Security group with unrestricted SSH access
resource "aws_security_group" "wide_open" {
  name        = "wide-open-sg"
  description = "Insecure security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # BAD: Open to the world
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # BAD: MySQL open to world
  }

  tags = {
    Environment = "production"
    Owner       = "security-team"
  }
}

# FAIL: No IAM password policy (checked at infrastructure level)

# ============================================================
# CC6.7 - Transit Encryption - VIOLATIONS
# ============================================================

# FAIL: HTTP load balancer listener
resource "aws_lb" "main" {
  name               = "main-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public.id]

  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"  # BAD: Should be HTTPS

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_target_group" "main" {
  name     = "main-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Supporting subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Environment = "production"
    Owner       = "network-team"
  }
}

# ============================================================
# CC7.1 - Availability - VIOLATIONS
# ============================================================

# FAIL: RDS without automated backups
resource "aws_db_instance" "no_backups" {
  identifier           = "no-backups-db"
  allocated_storage    = 20
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "changeme123"
  skip_final_snapshot  = true
  backup_retention_period = 0  # BAD: No backups
  
  tags = {
    Environment = "production"
    Owner       = "data-team"
  }
}

# WARNING: RDS not Multi-AZ (production)
resource "aws_db_instance" "single_az" {
  identifier          = "single-az-db"
  allocated_storage   = 20
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  username            = "admin"
  password            = "changeme123"
  skip_final_snapshot = true
  storage_encrypted   = true
  backup_retention_period = 7
  multi_az            = false  # WARNING: Should be true for prod
  
  tags = {
    Environment = "production"
    Owner       = "data-team"
  }
}

# WARNING: S3 without versioning
resource "aws_s3_bucket" "no_versioning" {
  bucket = "bucket-without-versioning"
  
  tags = {
    Environment = "production"
    Owner       = "backup-team"
  }
}

# ============================================================
# CC8.1 - Change Management - VIOLATIONS
# ============================================================

# FAIL: Resource without required tags
resource "aws_s3_bucket" "untagged" {
  bucket = "untagged-bucket"
  
  # Missing: Environment, Owner tags
}

# FAIL: EC2 instance without tags
resource "aws_instance" "untagged_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  # Missing: tags
}

# ============================================================
# PASSING EXAMPLES (for comparison)
# ============================================================

# PASS: Properly configured S3 bucket
resource "aws_s3_bucket" "compliant" {
  bucket = "fully-compliant-bucket"
  
  tags = {
    Environment = "production"
    Owner       = "security-team"
    Purpose     = "compliant-storage"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "compliant" {
  bucket = aws_s3_bucket.compliant.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "compliant" {
  bucket = aws_s3_bucket.compliant.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "compliant" {
  bucket = aws_s3_bucket.compliant.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "compliant" {
  bucket = aws_s3_bucket.compliant.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "compliant-bucket-logs/"
}

# Log bucket
resource "aws_s3_bucket" "logs" {
  bucket = "my-log-bucket"
  
  tags = {
    Environment = "production"
    Owner       = "security-team"
    Purpose     = "logs"
  }
}

# PASS: CloudTrail properly configured
resource "aws_cloudtrail" "main" {
  name                          = "main-trail"
  s3_bucket_name                = aws_s3_bucket.logs.id
  enable_logging                = true
  is_multi_region_trail         = true
  include_global_service_events = true

  tags = {
    Environment = "production"
    Owner       = "security-team"
  }
}

# PASS: RDS with all best practices
resource "aws_db_instance" "compliant_db" {
  identifier              = "compliant-db"
  allocated_storage       = 20
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "changeme123"
  skip_final_snapshot     = false
  final_snapshot_identifier = "compliant-db-final"
  
  # Encryption
  storage_encrypted       = true
  
  # Backups
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  
  # Availability
  multi_az                = true
  
  tags = {
    Environment = "production"
    Owner       = "data-team"
    Purpose     = "production-database"
  }
}

# PASS: Secure security group
resource "aws_security_group" "secure" {
  name        = "secure-sg"
  description = "Properly configured security group"
  vpc_id      = aws_vpc.main.id

  # Only allow SSH from corporate network
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # GOOD: Restricted range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "production"
    Owner       = "security-team"
  }
}

# PASS: HTTPS load balancer
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"  # GOOD: Encrypted
  certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
