FROM jenkins/inbound-agent:latest-alpine

# Install Packer
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

USER jenkins

RUN packer plugins install github.com/hashicorp/vsphere
RUN packer plugins install github.com/hashicorp/ansible
RUN packer plugins install github.com/hashicorp/azure
RUN packer plugins install github.com/mondoohq/cnspec
RUN packer plugins install github.com/hashicorp/ansible
