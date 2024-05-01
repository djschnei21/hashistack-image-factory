// variable "jenkins_efs" {
//   description = "EFS volume to store Jenkins data"
// }

job "jenkins" {
  datacenters = ["dc1"]
  type        = "service"
  node_pool   = "x86"

  group "jenkins" {
    count = 1

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