packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "aws_subnet_id" {
  type = string
  default = "subnet-66ca051b"
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

source "amazon-ebs" "aws-golden-ubuntu" {
  region                      = var.aws_region
  subnet_id                   = var.aws_subnet_id
  associate_public_ip_address = true
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-mantic-23.10-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"] # Canonical
    most_recent = true
  }
  instance_type = "t3a.small"
  ssh_username  = "ubuntu"
  ami_name      = "golden-ubuntu-{{timestamp}}"
  tags = {
    timestamp      = "{{timestamp}}"
  }
}

build {
  sources = [
    "source.amazon-ebs.aws-golden-ubuntu",
  ]

  hcp_packer_registry {
    bucket_name = "golden-ubuntu"
    description = "Ubuntu Mantic Minotaur Golden Image"

    bucket_labels = {
      "os"             = "Ubuntu",
      "ubuntu-version" = "23.10",
    }

    build_labels = {
      "timestamp"      = timestamp()
      "consul_enabled" = true
      "nomad_enabled" = true
    }
  }

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo apt update && sudo apt upgrade -y"
    ]
  }
}