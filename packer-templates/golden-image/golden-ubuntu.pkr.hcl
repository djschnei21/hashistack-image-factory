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

source "amazon-ebs" "golden-ubuntu" {
  region                      = var.aws_region
  subnet_id                   = var.aws_subnet_id
  associate_public_ip_address = true
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
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

source "azure-arm" "golden-ubuntu" {
  subscription_id                   = var.azure_subscription_id
  client_id                         = var.azure_client_id
  client_secret                     = var.azure_client_secret
  managed_image_name                = "golden-ubuntu-{{timestamp}}"
  os_type                           = "Linux"
  image_publisher                   = "Canonical"
  image_offer                       = "ubuntu-24_04-lts"
  image_sku                         = "server-gen1"

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
    "source.amazon-ebs.golden-ubuntu",
    "source.azure-arm.golden-ubuntu"
  ]

  hcp_packer_registry {
    bucket_name = "golden-ubuntu"
    description = "Ubuntu Noble Numbat Golden Image"

    bucket_labels = {
      "os"             = "Ubuntu",
      "ubuntu-version" = "24.04",
    }

    build_labels = {
      "timestamp"      = timestamp()
    }
  }

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo apt update && sudo apt upgrade -y",
      "curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.54.1",
      "sudo trivy rootfs --no-progress --scanners vuln --format json --output ${source.type}-${source.name}.json /",
      "cat ${source.type}-${source.name}.json | jq -r '[.Results[].Vulnerabilities[]?] | group_by(.Severity) | map({key: .[0].Severity, value: length}) | from_entries' >> ${source.type}-${source.name}-summary.json"
    ]
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