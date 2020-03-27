#####
# Download the latest version of retry
#####
FROM alpine:latest as retry-downloader

RUN apk --no-cache add curl

RUN curl --retry-connrefused --retry-delay 5 https://raw.githubusercontent.com/kadwanev/retry/master/retry -o /retry

#####
# Download the latest version of Terraform
#####
FROM alpine:latest AS terraform-downloader

RUN apk --no-cache add aria2 curl jq unzip

RUN curl --silent https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r '.tag_name' | tr -d 'v' > /terraform-version

RUN aria2c --max-connection-per-server=4 --min-split-size=1M --summary-interval=5 --download-result=full --out=/tf.zip https://releases.hashicorp.com/terraform/$(cat /terraform-version)/terraform_$(cat /terraform-version)_linux_amd64.zip

RUN unzip /tf.zip

RUN chmod 755 /terraform

#####
# Download the provisioners for Terraform
# Taken from: https://stackoverflow.com/questions/50944395/use-pre-installed-terraform-plugins-instead-of-downloading-them-with-terraform-i/50944611#50944611
#####
FROM golang:alpine AS terraform-bundler-build

RUN apk --no-cache add git unzip bash curl
RUN curl -sSL https://git.io/get-mo -o /usr/local/bin/mo && \
    chmod +x /usr/local/bin/mo

RUN go get -d -v github.com/hashicorp/terraform && \
    go install ./src/github.com/hashicorp/terraform/tools/terraform-bundle

COPY terraform-bundle.hcl.mo-template .
COPY --from=terraform-downloader /terraform-version .

RUN TFVER=$(cat terraform-version) mo --fail-not-set terraform-bundle.hcl.mo-template > terraform-bundle.hcl

RUN terraform-bundle package terraform-bundle.hcl && \
    mkdir -p terraform-bundle && \
    unzip -d terraform-bundle terraform_*.zip

#####
# Main image build
#####
FROM ubuntu:bionic

LABEL maintainer="EP/DevOps <rel-eng@elasticpath.com>"

ARG AWS_IAM_AUTHENTICATOR_URL="https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/aws-iam-authenticator"

# WARNING: this is a temporary fix until Ubuntu releases a version of apt after 1.6.12 which doesn't break package list downloads from some repos
RUN echo "apt hold" | dpkg --set-selections

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean all

# install retry
COPY --from=retry-downloader /retry /usr/local/bin/retry

RUN chmod 755 /usr/local/bin/retry

# install what we need to:
# clone the code (git)
# install Docker (apt-transport-https ca-certificates curl software-properties-common gpg-agent)
# install img (curl)
# dependencies for building images (unzip xmlstarlet jq ssh-keygen aria2c)
# dependencies for the AWS CLI (python)
# check Jenkins job parameters (dnsutils)
# dependencies to reset the Keycloak database (mysql-client)
RUN apt-get install --no-install-recommends -y \
      git apt-transport-https ca-certificates curl aria2 software-properties-common \
      gpg-agent uidmap unzip xmlstarlet jq python openssh-client dnsutils mysql-client && \
    apt-get clean all

# install the Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install --no-install-recommends -y docker-ce && \
    apt-get clean all

# install the AWS CLI
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py && \
    pip install --upgrade pip && \
    pip install --upgrade awscli

# install eksctl
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin/

# install aws-iam-authenticator
RUN curl -o aws-iam-authenticator "${AWS_IAM_AUTHENTICATOR_URL}" && \
    chmod +x ./aws-iam-authenticator && \
    mv ./aws-iam-authenticator /usr/local/bin/

# install the Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# install img
RUN curl -fSL "https://github.com/genuinetools/img/releases/download/v0.5.6/img-linux-amd64" -o "/usr/local/bin/img" \
    && echo "f5d686465a7463c296e94634bd9597af58544ead924567c9128a4ee352591bf1  /usr/local/bin/img" | sha256sum -c - \
    && chmod a+x "/usr/local/bin/img"

# install kubectl
# this installs the latest version available
RUN az aks install-cli

# install mo
RUN curl -sSL https://git.io/get-mo -o "/usr/local/bin/mo" && \
    chmod a+x "/usr/local/bin/mo"

# install Terraform
COPY --from=terraform-downloader /terraform /usr/local/bin/

# install the Terraform provisioners that were downloaded
COPY --from=terraform-bundler-build /go/terraform-bundle/* /usr/local/bin/
