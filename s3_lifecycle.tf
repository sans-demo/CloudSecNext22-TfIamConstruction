resource "aws_s3_bucket_lifecycle_configuration" "s3_by_hand_lifecycle_rules" {
  bucket = var.s3_bucket_name

  # Static rule 1 - move to Standard-IA after 30 days
  rule {
    status = "Enabled"
    id     = "Move Everything to Standard-IA after 30 Days"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }

  # Static rule 2 - Expire all noncurrent versions after 30 days
  rule {
    status = "Enabled"
    id     = "Expire all noncurrent versions after 30 Days"

    expiration {
      expired_object_delete_marker = true
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  # Dynamic rules built for each client
  dynamic "rule" {
    for_each = var.s3_policy_input
    content {
      id     = rule.key
      status = lookup(rule.value, "lifecycle_enabled", "Enabled")

      filter {
        prefix = "${rule.key}/"
      }

      abort_incomplete_multipart_upload {
        days_after_initiation = lookup(rule.value, "lifecycle_abort_incomplete_days", 7)
      }

      expiration {
        days                         = lookup(rule.value, "lifecycle_expiration_days", 100)
        expired_object_delete_marker = lookup(rule.value, "lifecycle_expired_object_delete_marker", false)
      }

      noncurrent_version_expiration {
        noncurrent_days = lookup(rule.value, "lifecycle_noncurrent_version_expiration_days", 120)
      }
    }
  }
}
