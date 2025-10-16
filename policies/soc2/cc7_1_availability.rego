# Copyright 2025 Kiln
# Licensed under the Apache License, Version 2.0

package soc2

# CC7.1 - System Availability

# RDS instances should have automated backups
violations[finding] {
    resource := input.resources[_]
    resource.type == "aws_db_instance"
    not has_automated_backups(resource)
    
    finding := {
        "control": "CC7.1",
        "severity": "high",
        "resource": resource.address,
        "message": sprintf("RDS instance '%s' has no automated backups", [resource.name]),
        "remediation": "Set backup_retention_period to at least 7 days"
    }
}

# Pass when RDS has automated backups
passed[finding] {
    resource := input.resources[_]
    resource.type == "aws_db_instance"
    has_automated_backups(resource)
    
    finding := {
        "control": "CC7.1",
        "resource": resource.address,
        "message": sprintf("RDS instance '%s' has automated backups configured", [resource.name])
    }
}

# RDS instances should be Multi-AZ for production
warnings[finding] {
    resource := input.resources[_]
    resource.type == "aws_db_instance"
    not resource.config.multi_az == true
    is_production(resource)
    
    finding := {
        "control": "CC7.1",
        "severity": "medium",
        "resource": resource.address,
        "message": sprintf("RDS instance '%s' is not Multi-AZ", [resource.name]),
        "remediation": "Set multi_az = true for high availability"
    }
}

# Pass when production RDS is Multi-AZ
passed[finding] {
    resource := input.resources[_]
    resource.type == "aws_db_instance"
    resource.config.multi_az == true
    is_production(resource)
    
    finding := {
        "control": "CC7.1",
        "resource": resource.address,
        "message": sprintf("RDS instance '%s' is Multi-AZ for high availability", [resource.name])
    }
}

# S3 buckets should have versioning
warnings[finding] {
    resource := input.resources[_]
    resource.type == "aws_s3_bucket"
    not has_versioning(resource)
    
    finding := {
        "control": "CC7.1",
        "severity": "medium",
        "resource": resource.address,
        "message": sprintf("S3 bucket '%s' has no versioning", [resource.name]),
        "remediation": "Add aws_s3_bucket_versioning with status = Enabled"
    }
}

# Pass when S3 has versioning
passed[finding] {
    resource := input.resources[_]
    resource.type == "aws_s3_bucket"
    has_versioning(resource)
    
    finding := {
        "control": "CC7.1",
        "resource": resource.address,
        "message": sprintf("S3 bucket '%s' has versioning enabled", [resource.name])
    }
}

# Helper: Check for automated backups
has_automated_backups(db) {
    to_number(db.config.backup_retention_period) >= 7
}

# Helper: Check if resource is production
is_production(resource) {
    resource.config.tags.Environment == "production"
}

is_production(resource) {
    resource.config.tags.Environment == "prod"
}

# Helper: Check for versioning
has_versioning(bucket) {
    versioning := input.resources[_]
    versioning.type == "aws_s3_bucket_versioning"
    bucket_matches_versioning(versioning.config.bucket, bucket)
}

has_versioning(bucket) {
    bucket.config.versioning[_].enabled == true
}

# Helper to match bucket references
bucket_matches_versioning(bucket_ref, resource) {
    bucket_ref == sprintf("%s.%s.id", [resource.type, resource.name])
}

bucket_matches_versioning(bucket_ref, resource) {
    bucket_ref == resource.address
}

bucket_matches_versioning(bucket_ref, resource) {
    bucket_ref == resource.name
}
