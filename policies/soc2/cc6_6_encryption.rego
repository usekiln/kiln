# Copyright 2025 Kiln
# Licensed under the Apache License, Version 2.0

package soc2

# CC6.6 - Encryption at Rest

# Deny unencrypted S3 buckets
violations[finding] {
    resource := input.resources[_]
    resource.type == "aws_s3_bucket"
    not has_encryption(resource)
    
    finding := {
        "control": "CC6.6",
        "severity": "critical",
        "resource": resource.address,
        "message": sprintf("S3 bucket '%s' does not have encryption enabled", [resource.name]),
        "remediation": "Add server_side_encryption_configuration block with AES256 or aws:kms"
    }
}

# Pass if encryption is configured
passed[finding] {
    resource := input.resources[_]
    resource.type == "aws_s3_bucket"
    has_encryption(resource)
    
    finding := {
        "control": "CC6.6",
        "resource": resource.address,
        "message": sprintf("S3 bucket '%s' has encryption enabled", [resource.name])
    }
}

# Helper: Check if S3 bucket has encryption
has_encryption(resource) {
    resource.config.server_side_encryption_configuration
}

# Alternative encryption check (for separate encryption resource)
has_encryption(resource) {
    encryption := input.resources[_]
    encryption.type == "aws_s3_bucket_server_side_encryption_configuration"
    # Match various reference formats
    bucket_matches(encryption.config.bucket, resource)
}

# Helper to match bucket references
bucket_matches(bucket_ref, resource) {
    # Direct reference: "aws_s3_bucket.example.id"
    bucket_ref == sprintf("%s.%s.id", [resource.type, resource.name])
}

bucket_matches(bucket_ref, resource) {
    # Resource address: "aws_s3_bucket.example"
    bucket_ref == resource.address
}

bucket_matches(bucket_ref, resource) {
    # Just the name
    bucket_ref == resource.name
}

# Deny unencrypted EBS volumes
violations[finding] {
    resource := input.resources[_]
    resource.type == "aws_ebs_volume"
    not resource.config.encrypted == true
    
    finding := {
        "control": "CC6.6",
        "severity": "critical",
        "resource": resource.address,
        "message": sprintf("EBS volume '%s' is not encrypted", [resource.name]),
        "remediation": "Set 'encrypted = true' on the aws_ebs_volume resource"
    }
}

# Deny unencrypted RDS instances
violations[finding] {
    resource := input.resources[_]
    resource.type == "aws_db_instance"
    not resource.config.storage_encrypted == true
    
    finding := {
        "control": "CC6.6",
        "severity": "critical",
        "resource": resource.address,
        "message": sprintf("RDS instance '%s' does not have storage encryption enabled", [resource.name]),
        "remediation": "Set 'storage_encrypted = true' on the aws_db_instance resource"
    }
}

# Pass for encrypted RDS
passed[finding] {
    resource := input.resources[_]
    resource.type == "aws_db_instance"
    resource.config.storage_encrypted == true
    
    finding := {
        "control": "CC6.6",
        "resource": resource.address,
        "message": sprintf("RDS instance '%s' has encryption enabled", [resource.name])
    }
}

# Evaluate entry point - aggregates all findings
evaluate = result {
    result := {
        "violations": violations,
        "warnings": warnings,
        "passed": passed
    }
}
