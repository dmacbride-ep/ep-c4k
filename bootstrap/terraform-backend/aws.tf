resource "aws_s3_bucket" "terraform_backend" {
  count = var.cloud == "aws" ? 1 : 0

  bucket = var.aws_backend_s3_bucket
  acl    = "private"

  tags = {
    Name = "${var.aws_backend_s3_bucket}"
  }
}

resource "aws_dynamodb_table" "terraform_backend" {
  count = var.cloud == "aws" ? 1 : 0

  name         = var.aws_backend_dynamodb_table
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}
