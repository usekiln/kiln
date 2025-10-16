# Copyright 2025 Kiln
# Licensed under the Apache License, Version 2.0

package soc2

# CC8.1 - Change Management and Configuration

# Resources should have proper tagging
violations[finding] {
    resource := input.resources[_]
    taggable_resource(resource.type)
    not has_required_tags(resource)
    
    finding := {
        "control": "CC8.1",
        "severity": "medium",
        "resource": resource.address,
        "message": sprintf("Resource '%s' is missing required tags", [resource.name]),
        "remediation": "Add tags: Environment and Owner"
    }
}

# S3 buckets should have versioning for change tracking
warnings[finding] {
    resource := input.resources[_]
    resource.type == "aws_s3_bucket"
    not has_versioning_enabled(resource)
    
    finding := {
        "control": "CC8.1",
        "severity": "low",
        "resource": resource.address,
        "message": sprintf("S3 bucket '%s' should enable versioning", [resource.name]),
        "remediation": "Enable versioning for change tracking"
    }
}

# Helper: Resources that should be tagged
taggable_resource(resource_type) {
    taggable_types := [
        "aws_s3_bucket",
        "aws_db_instance",
        "aws_instance",
        "aws_vpc",
        "aws_subnet",
        "aws_security_group",
        "aws_lb"
    ]
    taggable_types[_] == resource_type
}

# Helper: Check for required tags
has_required_tags(resource) {
    resource.config.tags.Environment
    resource.config.tags.Owner
}

# Helper: Check versioning
has_versioning_enabled(bucket) {
    versioning := input.resources[_]
    versioning.type == "aws_s3_bucket_versioning"
    bucket_matches_versioning_cc8(versioning.config.bucket, bucket)
}

# Helper to match bucket references
bucket_matches_versioning_cc8(bucket_ref, resource) {
    bucket_ref == sprintf("%s.%s.id", [resource.type, resource.name])
}

bucket_matches_versioning_cc8(bucket_ref, resource) {
    bucket_ref == resource.address
}

bucket_matches_versioning_cc8(bucket_ref, resource) {
    bucket_ref == resource.name
}
