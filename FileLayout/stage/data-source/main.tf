provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "exampledb" {
  instance_class = "db.t2.micro"
  identifier_prefix = "terraform-up-and-running"
  engine = "mysql"
  allocated_storage = 10
  name = "exampledb"
  username = "admin"
  password = "mysql-stage"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "mysql-master-password-stage"
}

terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-spk-145"
    key = "stage/data-stores/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
}