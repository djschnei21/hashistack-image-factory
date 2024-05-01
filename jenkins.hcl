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
        source    = "jenkins_volume"

        attachment_mode = "file-system"
        access_mode     = "multi-node-multi-writer"
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

    task "chown" {
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      volume_mount {
        volume      = "jenkins_home"
        destination = "/var/jenkins_home"
        read_only   = false
      }

      driver = "docker"

      config {
        image   = "busybox:stable"
        command = "sh"
        args    = ["-c", "chown -R 1000:1000 /var/jenkins_home"]
      }

      resources {
        cpu    = 200
        memory = 128
      }
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
        address = "${attr.unique.platform.aws.public-ipv4}"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}