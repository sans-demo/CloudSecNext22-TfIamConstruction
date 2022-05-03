terraform {
  required_version = "~> 1.1.2"

  required_providers {
    aws = {
      version = "~> 4.8.0"
      source  = "hashicorp/aws"
    }
  }
}

# Download AWS provider
provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Owner   = "Kyler"
      Twitter = "@KyMidd"
      Website = "Kyler.omg.lol"
    }
  }
}

# Create IAM users to ingest into policy
# These users would likely be provided by partners and encoded as strings in s3_policy_input below
# There is no dependency on creating the IAM users in our TF, or in any TF
resource "aws_iam_user" "partner_iam_users" {
  for_each = toset(
    [
      "Partner1",
      "Partner2",
      "Partner3",
      "Partner4",
      "Partner5",
      "Partner6",
      "Partner7a", "Partner7b", "Partner7c", # Partner7 has 3 IAM roles they'll use for access
      "Partner8",
      "Partner9",
      "Partner10",
      "Partner11",
      "Partner12",
    ]
  )
  name = each.key
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "kyler-iterated-testing-bucket"
}

resource "aws_s3_bucket_policy" "iterated_s3_policy" {
  bucket = aws_s3_bucket.s3_bucket.id

  # Constructed policy built by s3_policy module based on client info
  policy = module.s3_policy_and_lifecycle.constructed_policy
}

# Could optionally add other policies to the constructed policy:
/* 
data "aws_iam_policy_document" "combined" {
  source_policy_documents = [
  data.aws_iam_policy_document.deny_non_secure_transport.json #Generated policy
  data.aws_iam_policy_document.your_policy_to_add.json #Your policy heredoc or resource
]
*/

locals {
  partner_info = {
    "Partner1" = {
      principals = [aws_iam_user.partner_iam_users["Partner1"].arn]
    }
    "Partner2" = {
      principals = [aws_iam_user.partner_iam_users["Partner2"].arn]
      # The initial admin didn't use the "partner" standard, so we correct the folder path name communicated to this partner
      folder_name = "client2"
    }
    "Partner3" = {
      principals = [aws_iam_user.partner_iam_users["Partner3"].arn]
      # Partner3 required a shorter lifecycle expiration than the default, so we over-ride
      lifecycle_expiration_days = 30
    }
    "Partner4" = {
      principals = [aws_iam_user.partner_iam_users["Partner4"].arn]
    }
    "Partner5" = {
      principals = [aws_iam_user.partner_iam_users["Partner5"].arn]
      # S3 names are always case sensitive, so we need to correct if the created folder is lower-cased
      folder_name = "partner5"
    }
    "Partner6" = {
      principals                = [aws_iam_user.partner_iam_users["Partner6"].arn]
      lifecycle_expiration_days = 60
    }
    "Partner7" = {
      principals = [
        # Multiple principals are fully supported
        aws_iam_user.partner_iam_users["Partner7a"].arn,
        aws_iam_user.partner_iam_users["Partner7b"].arn,
        aws_iam_user.partner_iam_users["Partner7c"].arn,
      ]
    }
    "Partner8" = {
      principals = [aws_iam_user.partner_iam_users["Partner8"].arn]
    }
    "Partner9" = {
      principals = [aws_iam_user.partner_iam_users["Partner9"].arn]
    }
    "Partner10" = {
      principals = [aws_iam_user.partner_iam_users["Partner10"].arn]
    }
    "Partner11" = {
      principals                = [aws_iam_user.partner_iam_users["Partner11"].arn]
      folder_name               = "put_files_here_partner11"
      lifecycle_expiration_days = 75
    }
    "Partner12" = {
      principals  = [aws_iam_user.partner_iam_users["Partner12"].arn]
      folder_name = "dropbox"
    }
  }
}

module "s3_policy_and_lifecycle" {
  source = "github.com/sans-demo/CloudSecNext22-TfIamConstruction?ref=v1.2"
  s3_bucket_name = aws_s3_bucket.s3_bucket.id

  # The S3 folder name targeted by permissions is implicitly the Key value
  # This can be over-ridden with "folder_name" key if client name and folder name don't match
  s3_policy_input = local.partner_info
}

/* Build S3 bucket */
resource "aws_s3_bucket_versioning" "iterated_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "iterated_sse" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
