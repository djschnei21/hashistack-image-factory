variable "jenkins_efs" {
  description = "EFS volume to store Jenkins data"
}

job "jenkins" {
  datacenters = ["dc1"]
  type        = "service"
  node_pool   = "x86"

  group "jenkins" {
    count = 1

    volume "jenkins_home" {
        type      = "csi"
        read_only = false
        source    = var.jenkins_efs

        attachment_mode = "file-system"
        access_mode     = "multi-node-multi-writer"

        parameters  {
          provisioningMode = "efs-ap"
          OwnerUid = "1000"
          OwnerGid = "1000"
          gid      = "1000"
          uid      = "1000"
          fileSystemId = aws_efs_file_system.jenkins.id
        }
    }

    network {
        mode = "bridge"
        port "http" {
            static = 8080
            to     = 8080
        }
        port "jnlp" {
            static = 51000
            to     = 51000
        }
    }

    task "jenkins" {
      driver = "docker"

      volume_mount {
        volume      = "jenkins_home"
        destination = "/var/jenkins_home/shared"
        read_only   = false
      }

      config {
        image = "jenkins/jenkins:latest"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "jenkins"
        port = "http"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}