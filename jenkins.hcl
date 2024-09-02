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
        to = 8080
      }
      port "jnlp" {
        to = 50000
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

    task "install-plugins" {
      driver = "docker"
      volume_mount {
        volume      = "jenkins_home"
        destination = "/var/jenkins_home"
        read_only   = false
      }
      config {
        image   = "jenkins/jenkins:latest"
        command = "jenkins-plugin-cli"
        args    = ["-f", "/var/jenkins_home/plugins.txt", "--plugin-download-directory", "/var/jenkins_home/plugins/"]
        volumes = [
          "local/plugins.txt:/var/jenkins_home/plugins.txt",
        ]
      }
    
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      template {
        data = <<EOF
configuration-as-code
job-dsl
nomad
hashicorp-vault-plugin
git
pipeline-stage-view
EOF
        destination   = "local/plugins.txt"
        change_mode   = "noop"
      }

      resources {
        cpu    = 500
        memory = 1024
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
        volumes = [
          "local/jasc.yaml:/var/jenkins_home/jenkins.yaml",
        ]
      }

      template {
        data = <<EOF
jenkins:
  agentProtocols:
  - "JNLP4-connect"
  - "Ping"
  clouds:
  - nomad:
      name: "nomad"
      nomadUrl: "http://{{ env "attr.unique.network.ip-address" }}:4646"
      nomadACLCredentialsId: "687baaad-fa2d-49c8-8c11-ab0bf99f1f94"
      prune: true
      templates:
      - idleTerminationInMinutes: 10
        jobTemplate: |-
          {
            "Job": {
              "Region": "global",
              "ID": "%WORKER_NAME%",
              "Type": "batch",
              "NodePool": "x86",
              "Datacenters": [
                "dc1"
              ],
              "TaskGroups": [
                {
                  "Name": "jenkins-worker-taskgroup",
                  "Count": 1,
                  "RestartPolicy": {
                    "Attempts": 0,
                    "Interval": 10000000000,
                    "Mode": "fail",
                    "Delay": 1000000000
                  },
                  "Tasks": [
                    {
                      "Name": "jenkins-worker-jnlp",
                      "Driver": "docker",
                      "Vault": {
                        "Policies": ["nomad"]
                      },
                      "Config": {
                        "image": "djs21/jenkins-agent-packer:latest"
                      },
                      "Env": {
                        "JENKINS_URL": "http://{{ env "NOMAD_ADDR_http" }}",
                        "JENKINS_AGENT_NAME": "%WORKER_NAME%",
                        "JENKINS_SECRET": "%WORKER_SECRET%",
                        "JENKINS_TUNNEL": "{{ env "NOMAD_ADDR_jnlp" }}"
                      },
                      "Resources": {
                        "CPU": 500,
                        "MemoryMB": 256
                      }
                    }
                  ],
                  "EphemeralDisk": {
                    "SizeMB": 300
                  }
                }
              ]
            }
          }
        labels: "nomad"
        numExecutors: 1
        prefix: "jenkins-agent"
        reusable: true
      tlsEnabled: false
      workerTimeout: 1
  numExecutors: 0
jobs:
  - script: >
      job('packer-build-factory') {
        label('nomad')
        steps {
            shell('whoami')
            shell('packer --version')
        }
      }
EOF
        change_mode   = "noop"
        destination   = "local/jasc.yaml"
      }

      env {
        JAVA_OPTS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
      }

      resources {
        cpu    = 750
        memory = 1024
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