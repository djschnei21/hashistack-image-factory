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

data "hcp_packer_artifact" "tomcat-ubuntu" {
  bucket_name   = "tomcat-ubuntu"
  channel_name  = "latest"
  platform      = "aws"
  region        = "us-east-2"
}

resource "aws_instance" "tomcat" {
  ami           = data.hcp_packer_artifact.tomcat-ubuntu.external_identifier
  instance_type = "t3.micro"

  tags = {
    Name = "HelloWorld"
  }
}