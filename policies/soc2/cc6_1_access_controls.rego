# Copyright 2025 Kiln
# Licensed under the Apache License, Version 2.0

package soc2

# CC6.1 - Logical Access Controls

# S3 buckets must block public access
violations[finding] {
    resource := input.resources[_]
    resource.type == "aws_s3_bucket"
    not has_public_access_block(resource)
    
    finding := {
        "control": "CC6.1",
        "severity": "critical",
        "resource": resource.address,
        "message": sprintf("S3 bucket '%s' does not block public access", [resource.name]),
        "remediation": "Add aws_s3_bucket_public_access_block with all settings true"
    }
}

# Security groups should not allow unrestricted access
violations[finding] {
    resource := input.resources[_]
    resource.type == "aws_security_group"
    has_unrestricted_ingress(resource)
    
    finding := {
        "control": "CC6.1",
        "severity": "critical",
        "resource": resource.address,
        "message": sprintf("Security group '%s' allows unrestricted access to sensitive ports", [resource.name]),
        "remediation": "Restrict ingress to specific IP ranges"
    }
}

# Helper: Check if bucket has public access block
has_public_access_block(bucket) {
    block := input.resources[_]
    block.type == "aws_s3_bucket_public_access_block"
    bucket_matches_block(block.config.bucket, bucket)
    all_public_access_blocked(block)
}

# Helper to match bucket references
bucket_matches_block(bucket_ref, resource) {
    bucket_ref == sprintf("%s.%s.id", [resource.type, resource.name])
}

bucket_matches_block(bucket_ref, resource) {
    bucket_ref == resource.address
}

bucket_matches_block(bucket_ref, resource) {
    bucket_ref == resource.name
}

# Helper: Verify all public access settings are blocked
all_public_access_blocked(block) {
    block.config.block_public_acls == true
    block.config.block_public_policy == true
    block.config.ignore_public_acls == true
    block.config.restrict_public_buckets == true
}

# Helper: Check for unrestricted ingress
has_unrestricted_ingress(sg) {
    ingress := sg.config.ingress[_]
    contains_cidr(ingress.cidr_blocks, "0.0.0.0/0")
    sensitive_port(ingress)
}

sensitive_port(ingress) {
    sensitive_ports := [22, 3389, 1433, 3306, 5432, 6379, 27017]
    port := ingress.from_port
    sensitive_ports[_] == port
}

contains_cidr(cidrs, target) {
    cidrs[_] == target
}
