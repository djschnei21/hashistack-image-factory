terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "~> 3.18.0"
    }

    nomad = {
      source = "hashicorp/nomad"
      version = "2.2.0"
    }
    
    doormat = {
      source  = "doormat.hashicorp.services/hashicorp-security/doormat"
      version = "~> 0.0.6"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }
  }
}

provider "doormat" {}

data "doormat_aws_credentials" "creds" {
  provider = doormat
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/tfc-doormat-role_hashistack-image-factory"
}

provider "aws" {
  region     = var.region
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}

data "terraform_remote_state" "nomad_cluster" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "5_nomad-cluster"
    }
  }
}

data "terraform_remote_state" "network" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "1_network"
    }
  }
}

provider "vault" {}

data "vault_kv_secret_v2" "bootstrap" {
  mount = data.terraform_remote_state.nomad_cluster.outputs.bootstrap_kv
  name  = "nomad_bootstrap/SecretID"
}

provider "nomad" {
  address = data.terraform_remote_state.nomad_cluster.outputs.nomad_public_endpoint
  secret_id = data.vault_kv_secret_v2.bootstrap.data["SecretID"]
}

resource "aws_efs_file_system" "jenkins" {
  creation_token = "jenkins"
  encrypted      = true


  tags = {
    Name = "Jenkins"
  }
}

resource "aws_efs_mount_target" "jenkins" {
  for_each = data.terraform_remote_state.network.outputs.subnet_ids
  file_system_id  = aws_efs_file_system.jenkins.id
  subnet_id       = each.value  
  security_groups = ["sg-08d973af47615a208"] // replace with your security group
}

data "nomad_plugin" "efs" {
  plugin_id        = "aws-efs0"
  wait_for_healthy = true
}

resource "nomad_csi_volume_registration" "jenkins" {
  depends_on = [data.nomad_plugin.efs]

  plugin_id   = "aws-efs0"
  volume_id   = "jenkins_volume"
  name        = "jenkins_volume"
  external_id = aws_efs_file_system.jenkins.id

  capability {
    access_mode     = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  parameters = {
    mount_target_id = aws_efs_mount_target.jenkins.id
    uid = "1000"
  }
}

resource "nomad_job" "jenkins" {
  jobspec = file("${path.module}/jenkins.hcl")

  hcl2 {
    vars = {
      jenkins_efs = nomad_csi_volume_registration.jenkins.volume_id
    }
  }
}



