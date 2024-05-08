packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
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

variable "azure_location" {
  type = string
  default = "us-east"
}

variable "azure_resource_group" {
  type    = string
  default = "azure-lab"
}

variable "azure_subscription_id" {
  type = string
  default = "fd26d62d-dc30-4fe7-b18f-c590d20391a9"
}

variable "azure_client_id" {
  type = string
  default = null
}

variable "azure_client_secret" {
  type = string
  default = null
}

data "hcp-packer-artifact" "aws-golden-ubuntu" {
  bucket_name   = "golden-ubuntu"
  channel_name  = "release"
  platform      = "aws"
  region        = "us-east-2"
}

data "hcp-packer-artifact" "azure-golden-ubuntu" {
  bucket_name   = "golden-ubuntu"
  channel_name  = "release"
  platform      = "azure"
  region        = "eastus"
}

source "amazon-ebs" "tomcat-ubuntu" {
  region                      = var.aws_region
  subnet_id                   = var.aws_subnet_id
  associate_public_ip_address = true
  source_ami                  = data.hcp-packer-artifact.aws-golden-ubuntu.external_identifier
  instance_type = "t3a.small"
  ssh_username  = "ubuntu"
  ami_name      = "tomcat-ubuntu-{{timestamp}}"
  tags = {
    timestamp      = "{{timestamp}}"
  }
}

source "azure-arm" "tomcat-ubuntu" {
  subscription_id                   = var.azure_subscription_id
  client_id                         = var.azure_client_id
  client_secret                     = var.azure_client_secret
  managed_image_name                = "tomcat-ubuntu-{{timestamp}}"
  os_type                           = "Linux"
  custom_managed_image_resource_group_name = var.azure_resource_group
  custom_managed_image_name = "${split("/", data.hcp-packer-artifact.azure-golden-ubuntu.external_identifier)[length(split("/", data.hcp-packer-artifact.azure-golden-ubuntu.external_identifier)) - 1]}"

  build_resource_group_name         = var.azure_resource_group  # Existing resource group for VM build
  managed_image_resource_group_name = var.azure_resource_group  # Same group for storing the managed image

  vm_size                           = "Standard_B1s"
  communicator                      = "ssh"
  ssh_username                      = "ubuntu"

  azure_tags = {
    timestamp = "{{timestamp}}"
  }
}

build {
  sources = [
    "source.amazon-ebs.tomcat-ubuntu",
    "source.azure-arm.tomcat-ubuntu"
  ]

  hcp_packer_registry {
    bucket_name = "tomcat-ubuntu"
    description = "Ubuntu Mantic Minotaur Tomcat Image"

    bucket_labels = {
      "os"             = "Ubuntu",
      "ubuntu-version" = "23.10",
    }

    build_labels = {
      "timestamp"      = timestamp()
    }
  }

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo apt install tomcat9 -y",
      "sudo trivy rootfs --no-progress --scanners vuln --format json --output ${source.type}-${source.name}.json /",
      "cat ${source.type}-${source.name}.json | jq -r '[.Results[].Vulnerabilities[]] | group_by(.Severity) | map({key: .[0].Severity, value: length}) | from_entries' >> ${source.type}-${source.name}-summary.json"
    ]
  }

  provisioner "file" {
    source = "${source.type}-${source.name}.json"
    destination = "./"
    direction = "download"
  }

  provisioner "file" {
    source = "${source.type}-${source.name}-summary.json"
    destination = "./"
    direction = "download"
  }

  provisioner "shell-local" {
    inline = [
      "echo ${packer.versionFingerprint} >> fingerprint.txt"
    ]
  }
}