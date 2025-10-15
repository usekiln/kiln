# Example Terraform file with intentional compliance violations
# This file is used for testing the scanner

# VIOLATION: S3 bucket without encryption
resource "aws_s3_bucket" "user_data" {
  bucket = "my-user-data-bucket"
  acl    = "private"
  
  # Missing: server_side_encryption_configuration
  
  tags = {
    Environment = "production"
    Purpose     = "user-data"
  }
}

# PASS: S3 bucket with encryption enabled
resource "aws_s3_bucket" "logs" {
  bucket = "my-logs-bucket"
  acl    = "private"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  tags = {
    Environment = "production"
    Purpose     = "logs"
  }
}

# VIOLATION: EBS volume without encryption
resource "aws_ebs_volume" "data" {
  availability_zone = "us-west-2a"
  size              = 100
  
  # Missing: encrypted = true
  
  tags = {
    Name = "data-volume"
  }
}

# VIOLATION: RDS instance without encryption
resource "aws_db_instance" "primary" {
  identifier           = "mydb"
  allocated_storage    = 20
  storage_type        = "gp2"
  engine              = "postgres"
  engine_version      = "13.7"
  instance_class      = "db.t3.micro"
  username            = "admin"
  password            = "changeme123"
  
  # Missing: storage_encrypted = true
  
  skip_final_snapshot = true
  
  tags = {
    Environment = "production"
  }
}

# Example of a properly configured resource
resource "aws_ebs_volume" "encrypted_data" {
  availability_zone = "us-west-2a"
  size              = 50
  encrypted         = true
  kms_key_id       = "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  
  tags = {
    Name = "encrypted-data-volume"
  }
}
