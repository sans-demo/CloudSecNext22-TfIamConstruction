# Create IAM users to ingest into policy
resource "aws_iam_user" "partner_iam_users" {
  for_each = toset(
    [
      "TerraformRules",
      "AFCRichmond",
      "Partner3a", "Partner3b", "Partner3c",
      "Partner4",
    ]
  )
  name = each.key
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "kyler-iterated-testing-bucket"
}

module "s3_policy_and_lifecycle" {
  source = "github.com/sans-demo/CloudSecNext22-TfIamConstruction/code?ref=v1.0"
  s3_bucket_name = aws_s3_bucket.s3_bucket.id

  s3_policy_input = {
    "TerraformRules" = {
      principals = [aws_iam_user.partner_iam_users["TerraformRules"].arn]
    }
    "AFCRichmond" = {
      principals  = [aws_iam_user.partner_iam_users["AFCRichmond"].arn]
      folder_name = "TedLasso"
    }
    "Partner3" = {
      principals = [
        aws_iam_user.partner_iam_users["Partner3a"].arn,
        aws_iam_user.partner_iam_users["Partner3b"].arn,
        aws_iam_user.partner_iam_users["Partner3c"].arn,
      ]
    }
    "Partner4" = {
      principals = [
        aws_iam_user.partner_iam_users["Partner4"].arn,
      ]
    }
  }
}

# Apply the created S3 bucket policy
resource "aws_s3_bucket_policy" "iterated_s3_policy" {
  bucket = aws_s3_bucket.s3_bucket.id

  # Constructed policy built by s3_policy module based on client info
  policy = module.s3_policy_and_lifecycle.constructed_policy
}

/*
## Output policy
output "constructed_policy" {
  value = module.s3_policy_and_lifecycle.constructed_policy
}
*/


# Could optionally add other policies to the constructed policy:
/* 
data "aws_iam_policy_document" "combined" {
  source_policy_documents = [
    module.s3_policy_and_lifecycle.constructed_policy #Generated policy
    data.aws_iam_policy_document.your_policy_to_add.json #Your policy heredoc or resource
  ]
}
*/


# Other S3 attributes
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
