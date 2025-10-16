# Copyright 2025 Kiln
# Licensed under the Apache License, Version 2.0

package soc2

# CC6.7 - Data in Transit Encryption

# Load balancer listeners must use HTTPS/TLS
violations[finding] {
    resource := input.resources[_]
    resource.type == "aws_lb_listener"
    resource.config.protocol == "HTTP"
    not is_http_redirect(resource)
    
    finding := {
        "control": "CC6.7",
        "severity": "critical",
        "resource": resource.address,
        "message": sprintf("Load balancer listener '%s' uses unencrypted HTTP", [resource.name]),
        "remediation": "Change protocol to HTTPS and add certificate_arn, or redirect HTTP to HTTPS"
    }
}

# ALB listeners must use HTTPS/TLS
violations[finding] {
    resource := input.resources[_]
    resource.type == "aws_alb_listener"
    resource.config.protocol == "HTTP"
    not is_http_redirect(resource)
    
    finding := {
        "control": "CC6.7",
        "severity": "critical",
        "resource": resource.address,
        "message": sprintf("ALB listener '%s' uses unencrypted HTTP", [resource.name]),
        "remediation": "Change protocol to HTTPS and add certificate_arn, or redirect HTTP to HTTPS"
    }
}

# Helper: Check if HTTP listener is redirecting to HTTPS
is_http_redirect(listener) {
    # Check if default_action exists and has redirect
    listener.config.default_action.type == "redirect"
    listener.config.default_action.redirect.protocol == "HTTPS"
}

is_http_redirect(listener) {
    # Check for array of default_actions
    action := listener.config.default_action[_]
    action.type == "redirect"
    action.redirect.protocol == "HTTPS"
}

# S3 buckets should require HTTPS
warnings[finding] {
    resource := input.resources[_]
    resource.type == "aws_s3_bucket"
    not has_https_policy(resource)
    
    finding := {
        "control": "CC6.7",
        "severity": "medium",
        "resource": resource.address,
        "message": sprintf("S3 bucket '%s' does not enforce HTTPS-only access", [resource.name]),
        "remediation": "Add aws_s3_bucket_policy requiring aws:SecureTransport"
    }
}

# Helper: Check for HTTPS enforcement policy
has_https_policy(bucket) {
    policy := input.resources[_]
    policy.type == "aws_s3_bucket_policy"
    bucket_matches_policy(policy.config.bucket, bucket)
    contains(policy.config.policy, "aws:SecureTransport")
}

# Helper to match bucket references
bucket_matches_policy(bucket_ref, resource) {
    bucket_ref == sprintf("%s.%s.id", [resource.type, resource.name])
}

bucket_matches_policy(bucket_ref, resource) {
    bucket_ref == resource.address
}

bucket_matches_policy(bucket_ref, resource) {
    bucket_ref == resource.name
}
