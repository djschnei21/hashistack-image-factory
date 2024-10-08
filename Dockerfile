
# This Dockerfile sets up a Jenkins inbound agent with additional tools for HashiStack image factory.
# It installs the following packages:
# - wget
# - unzip
# - jq
# - ansible
# - python3
# It also downloads and installs the following HashiCorp tools:
# - Packer (version 1.11.2)
# - Vault (version 1.17.6)
# - Terraform (version 1.9.6)
# Finally, it installs several Packer plugins for different platforms and configurations.

FROM jenkins/inbound-agent:latest-alpine

USER root

RUN apk add --no-cache \
    wget \ 
    unzip \
    jq \
    ansible \ 
    python3

RUN wget https://releases.hashicorp.com/packer/1.11.2/packer_1.11.2_linux_amd64.zip \
    && unzip -o packer_1.11.2_linux_amd64.zip \
    && mv packer /usr/local/bin/packer

RUN wget https://releases.hashicorp.com/vault/1.17.6/vault_1.17.6_linux_amd64.zip \
    && unzip -o vault_1.17.6_linux_amd64.zip \
    && mv vault /usr/local/bin/vault

RUN wget https://releases.hashicorp.com/terraform/1.9.6/terraform_1.9.6_linux_amd64.zip \
    && unzip -o terraform_1.9.6_linux_amd64.zip \
    && mv terraform /usr/local/bin/terraform

USER jenkins

RUN packer plugins install github.com/hashicorp/vsphere
RUN packer plugins install github.com/hashicorp/ansible
RUN packer plugins install github.com/hashicorp/azure
RUN packer plugins install github.com/mondoohq/cnspec
RUN packer plugins install github.com/hashicorp/ansible