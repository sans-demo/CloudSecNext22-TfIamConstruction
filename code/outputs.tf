output "constructed_policy" {
  description = "IAM policy constructed by Terraform"
  value       = data.aws_iam_policy_document.combined.json
}
