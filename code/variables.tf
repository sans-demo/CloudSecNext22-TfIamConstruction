variable "s3_policy_input" {
  description = "Name of client (and often folder) as parent to principal and sometimes arbitrary folder name"
}
variable "s3_bucket_name" {
  description = "Name of the S3 bucket to apply policy to"
  type        = string
}