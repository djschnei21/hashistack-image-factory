FROM jenkins/inbound-agent:latest-alpine

# Install Packer
USER root
RUN apk add --no-cache \
    wget \ 
    unzip
RUN wget https://releases.hashicorp.com/packer/1.7.2/packer_1.7.2_linux_amd64.zip \
    && unzip packer_1.7.2_linux_amd64.zip \
    && mv packer /usr/local/bin/packer

USER jenkins
