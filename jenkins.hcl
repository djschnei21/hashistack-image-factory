variable "jenkins_efs" {
  description = "EFS volume to store Jenkins data"
}

job "jenkins" {
  datacenters = ["dc1"]
  type        = "service"

  group "jenkins" {
    count = 1

    volume "jenkins_home" {
      type      = "csi"
      read_only = false
      source    = var.jenkins_efs
    }

    task "jenkins" {
      driver = "docker"

      volume_mount {
        volume      = "jenkins_home"
        destination = "/var/jenkins_home"
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