FROM jenkins/inbound-agent:latest-alpine

# Install Packer
USER root

RUN apk add --no-cache \
    wget \ 
    unzip \
    jq

RUN wget https://releases.hashicorp.com/packer/1.10.3/packer_1.10.3_linux_amd64.zip \
    && unzip packer_1.10.3_linux_amd64.zip \
    && mv packer /usr/local/bin/packer

RUN wget https://releases.hashicorp.com/vault/1.16.2/vault_1.16.2_linux_amd64.zip \
    && unzip vault_1.16.2_linux_amd64.zip \
    && mv vault /usr/local/bin/vault

USER jenkins