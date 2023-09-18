resource "aws_s3_bucket" "example_bucket" {
  bucket = "pipeline-artifact-terraform-pipeline"
  acl    = "private" # Access Control List (ACL) for the bucket
}