provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform-s3-bucket" {
  bucket = "terraform-up-and-running-spk-145"

  lifecycle {
    prevent_destroy = true
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform-dynamodb-table" {
  hash_key = "LockID"
  name = "terraform-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
}

/*
terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-spk-145"
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
}
*/

terraform {
  backend "s3" {
    key = "global/s3/terraform.tfstate"
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform-s3-bucket.arn
}

output "dynamo_db_table" {
  value = aws_dynamodb_table.terraform-dynamodb-table.name
}
