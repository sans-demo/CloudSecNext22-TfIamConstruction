###
# Policy construction handled entirely by terraform
# Could optionally add conditional flags to turn on and off access levels for different clients
###

# Deny non-secure transport
data "aws_iam_policy_document" "deny_non_secure_transport" {
  statement {
    sid    = "DenyNonSecureTransport" #Must be unique
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "*",
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

# Create S3 allow policy document
data "aws_iam_policy_document" "s3_allow_list" {
  for_each = var.s3_policy_input
  statement {
    sid    = "AllowListOf${each.key}Folder" #Must be unique
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        for principals in each.value.principals : principals
      ]
    }
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        try(
          "${each.value.folder_name}/",
          "${each.key}/*"
        )
      ]
    }
  }
}

# Create S3 allow read delete policy document
data "aws_iam_policy_document" "s3_allow_read_delete_list" {
  for_each = var.s3_policy_input
  statement {
    sid    = "AllowReadDeleteTo${each.key}Folder" #Must be unique
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        for principals in each.value.principals : principals
      ]
    }
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:DeleteObject",
    ]
    resources = [
      try(
        "arn:aws:s3:::${var.s3_bucket_name}/${each.value.folder_name}/*",
        "arn:aws:s3:::${var.s3_bucket_name}/${each.key}/*"
      ),
    ]
  }
}

# Create S3 allow write to folder policy document
data "aws_iam_policy_document" "s3_allow_write" {
  for_each = var.s3_policy_input
  statement {
    sid    = "AllowWriteTo${each.key}Folder" #Must be unique
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        for principals in each.value.principals : principals
      ]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      try(
        "arn:aws:s3:::${var.s3_bucket_name}/${each.value.folder_name}/*",
        "arn:aws:s3:::${var.s3_bucket_name}/${each.key}/*"
      ),
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values = [
        "bucket-owner-full-control"
      ]
    }
  }
}

# Create S3 deny non-folder actions document
data "aws_iam_policy_document" "s3_deny_non_home" {
  for_each = var.s3_policy_input
  statement {
    sid    = "DenyNon${each.key}Requests" #Must be unique
    effect = "Deny"
    principals {
      type = "AWS"
      identifiers = [
        for principals in each.value.principals : principals
      ]
    }
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
    ]
    condition {
      test     = "StringNotLike"
      variable = "s3:prefix"
      values = [
        try(
          "${each.value.folder_name}/*",
          "${each.key}/*"
        ),
        "",
      ]
    }
    condition {
      test     = "Null"
      variable = "s3:prefix"
      values = [
        "false",
      ]
    }
  }
}

# Combine docs
# Using try() here since any of these documents could be optionally not created
data "aws_iam_policy_document" "combined" {
  source_policy_documents = flatten(
    [
      try(data.aws_iam_policy_document.deny_non_secure_transport.json, null),
      try([for k, v in data.aws_iam_policy_document.s3_allow_list : v.json], null),
      try([for k, v in data.aws_iam_policy_document.s3_allow_read_delete_list : v.json], null),
      try([for k, v in data.aws_iam_policy_document.s3_allow_write : v.json], null),
      try([for k, v in data.aws_iam_policy_document.s3_deny_non_home : v.json], null),
    ]
  )
}