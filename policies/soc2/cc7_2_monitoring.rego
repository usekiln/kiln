# Copyright 2025 Kiln
# Licensed under the Apache License, Version 2.0

package soc2

# CC7.2 - System Monitoring and Logging

# CloudTrail must be enabled
violations[finding] {
    count([r | r := input.resources[_]; r.type == "aws_cloudtrail"]) == 0
    
    finding := {
        "control": "CC7.2",
        "severity": "critical",
        "resource": "infrastructure",
        "message": "No CloudTrail configured for API logging",
        "remediation": "Add aws_cloudtrail resource with enable_logging = true"
    }
}

# CloudTrail must have logging enabled
violations[finding] {
    resource := input.resources[_]
    resource.type == "aws_cloudtrail"
    not resource.config.enable_logging == true
    
    finding := {
        "control": "CC7.2",
        "severity": "critical",
        "resource": resource.address,
        "message": sprintf("CloudTrail '%s' has logging disabled", [resource.name]),
        "remediation": "Set enable_logging = true"
    }
}

# Pass when CloudTrail is properly configured
passed[finding] {
    resource := input.resources[_]
    resource.type == "aws_cloudtrail"
    resource.config.enable_logging == true
    
    finding := {
        "control": "CC7.2",
        "resource": resource.address,
        "message": sprintf("CloudTrail '%s' has logging enabled", [resource.name])
    }
}

# CloudTrail should be multi-region
warnings[finding] {
    resource := input.resources[_]
    resource.type == "aws_cloudtrail"
    not resource.config.is_multi_region_trail == true
    
    finding := {
        "control": "CC7.2",
        "severity": "medium",
        "resource": resource.address,
        "message": sprintf("CloudTrail '%s' is not multi-region", [resource.name]),
        "remediation": "Set is_multi_region_trail = true"
    }
}

# Pass when CloudTrail is multi-region
passed[finding] {
    resource := input.resources[_]
    resource.type == "aws_cloudtrail"
    resource.config.is_multi_region_trail == true
    
    finding := {
        "control": "CC7.2",
        "resource": resource.address,
        "message": sprintf("CloudTrail '%s' is multi-region", [resource.name])
    }
}

# S3 buckets should have access logging
warnings[finding] {
    resource := input.resources[_]
    resource.type == "aws_s3_bucket"
    not has_s3_logging(resource)
    
    finding := {
        "control": "CC7.2",
        "severity": "medium",
        "resource": resource.address,
        "message": sprintf("S3 bucket '%s' has no access logging", [resource.name]),
        "remediation": "Add aws_s3_bucket_logging resource"
    }
}

# Pass when S3 has logging
passed[finding] {
    resource := input.resources[_]
    resource.type == "aws_s3_bucket"
    has_s3_logging(resource)
    
    finding := {
        "control": "CC7.2",
        "resource": resource.address,
        "message": sprintf("S3 bucket '%s' has access logging enabled", [resource.name])
    }
}

# VPCs should have flow logs
violations[finding] {
    resource := input.resources[_]
    resource.type == "aws_vpc"
    not has_flow_logs(resource)
    
    finding := {
        "control": "CC7.2",
        "severity": "high",
        "resource": resource.address,
        "message": sprintf("VPC '%s' has no flow logs", [resource.name]),
        "remediation": "Add aws_flow_log resource"
    }
}

# Pass when VPC has flow logs
passed[finding] {
    resource := input.resources[_]
    resource.type == "aws_vpc"
    has_flow_logs(resource)
    
    finding := {
        "control": "CC7.2",
        "resource": resource.address,
        "message": sprintf("VPC '%s' has flow logs enabled", [resource.name])
    }
}

# Helper: Check if S3 has logging
has_s3_logging(bucket) {
    logging := input.resources[_]
    logging.type == "aws_s3_bucket_logging"
    bucket_matches_logging(logging.config.bucket, bucket)
}

has_s3_logging(bucket) {
    bucket.config.logging
}

# Helper: Check if VPC has flow logs
has_flow_logs(vpc) {
    flow_log := input.resources[_]
    flow_log.type == "aws_flow_log"
    vpc_matches(flow_log.config.vpc_id, vpc)
}

# Helper to match bucket references
bucket_matches_logging(bucket_ref, resource) {
    bucket_ref == sprintf("%s.%s.id", [resource.type, resource.name])
}

bucket_matches_logging(bucket_ref, resource) {
    bucket_ref == resource.address
}

bucket_matches_logging(bucket_ref, resource) {
    bucket_ref == resource.name
}

# Helper to match VPC references
vpc_matches(vpc_ref, resource) {
    vpc_ref == sprintf("%s.%s.id", [resource.type, resource.name])
}

vpc_matches(vpc_ref, resource) {
    vpc_ref == resource.address
}

vpc_matches(vpc_ref, resource) {
    vpc_ref == resource.name
}
