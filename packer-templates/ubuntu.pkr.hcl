variable "subnet_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-2"
}

source "amazon-ebs" "amd" {
  region                      = var.region
  subnet_id                   = var.subnet_id
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
  instance_type = "t3a.medium"
  ssh_username  = "ubuntu"
  ami_name      = "amd64-{{timestamp}}"
  tags = {
    timestamp      = "{{timestamp}}"
    consul_enabled = true
    nomad_enabled = true
  }
}

source "amazon-ebs" "arm" {
  region                      = var.region
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-mantic-23.10-arm64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"] # Canonical
    most_recent = true
  }
  instance_type = "t4g.medium"
  ssh_username  = "ubuntu"
  ami_name      = "arm64-{{timestamp}}"
  tags = {
    timestamp      = "{{timestamp}}"
    consul_enabled = true
    nomad_enabled = true
  }
}

build {
  sources = [
    "source.amazon-ebs.amd",
    "source.amazon-ebs.arm"
  ]

  // hcp_packer_registry {
  //   bucket_name = "ubuntu-mantic-hashi"
  //   description = "Ubuntu Mantic Minotaur with Nomad and Consul installed"

  //   bucket_labels = {
  //     "os"             = "Ubuntu",
  //     "ubuntu-version" = "23.10",
  //   }

  //   build_labels = {
  //     "timestamp"      = timestamp()
  //     "consul_enabled" = true
  //     "nomad_enabled" = true
  //   }
  // }

  provisioner "shell" {
    inline = [
      "sudo apt update && sudo apt upgrade -y"
    ]
  }
}