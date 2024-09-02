terraform {
  required_providers {
    hcp = {
      source = "hashicorp/hcp"
      version = "0.88.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }
  }
}

provider "hcp" {}

provider "aws" {}

data "hcp_packer_artifact" "apache-ubuntu" {
  bucket_name   = "apache-ubuntu"
  channel_name  = "release"
  platform      = "aws"
  region        = "us-east-2"
}

resource "aws_instance" "apache" {
  ami           = data.hcp_packer_artifact.apache-ubuntu.external_identifier
  instance_type = "t3.micro"

  tags = {
    Name = "HelloWorld"
  }
}