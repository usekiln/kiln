resource "aws_db_instance" "primary" {
  identifier              = "app-database"
  allocated_storage       = 100
  engine                  = "postgres"
  engine_version          = "14.7"
  instance_class          = "db.r5.large"
  username                = "admin"
  password                = "changeme123"
  
  # CC6.6 - Encryption
  storage_encrypted       = true
  
  # CC7.1 - Availability
  backup_retention_period = 30
  multi_az                = true
  
  skip_final_snapshot     = false
  final_snapshot_identifier = "app-db-final"
  
  tags = {
    Environment = "production"
    Owner       = "data-team"
  }
}
