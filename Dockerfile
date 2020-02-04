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

ARG AWS_IAM_AUTHENTICATOR_URL="https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/aws-iam-authenticator"

# update installed packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl dnsutils && \
    apt-get clean all

# install retry
COPY --from=retry-downloader /retry /usr/local/bin/retry

RUN chmod 755 /usr/local/bin/retry

# install Terraform
COPY --from=terraform-downloader /terraform /usr/local/bin/

# install eksctl
RUN curl --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin

# install the Azure CLI
# this follows Microsoft's docs from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt
RUN apt-get update && \
    apt-get install -y apt-transport-https lsb-release software-properties-common dirmngr && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv --keyserver packages.microsoft.com \
      --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF && \
    apt-get update && \
    apt-get install -y azure-cli && \
    apt-get clean all

# install the aks-preview extension
# this is required to set IP CIDRs on the Kubernetes API
# see: https://docs.microsoft.com/en-us/azure/aks/api-server-authorized-ip-ranges
RUN az extension add --name aks-preview

# install kubectl
RUN az aks install-cli

# install the Mustache templating engine
RUN curl -sSL https://git.io/get-mo -o /usr/local/bin/mo && \
    chmod 755 /usr/local/bin/mo

# install aws-iam-authenticator
RUN curl -o /usr/local/bin/aws-iam-authenticator "${AWS_IAM_AUTHENTICATOR_URL}" && \
    chmod 755 /usr/local/bin/aws-iam-authenticator

# install any extra tools we need
RUN apt-get install -y openssh-client jq && \
    apt-get clean all

# install the Terraform provisioners that were downloaded
COPY --from=terraform-bundler-build /go/terraform-bundle/* /usr/local/bin/

# add any extra files that we need
COPY bootstrap/terraform-backend /root/bootstrap/terraform-backend
COPY bootstrap/terraform /root/bootstrap/terraform
COPY bootstrap/eksctl.yaml.mo-template /root/bootstrap/

COPY bootstrap/entrypoint.sh /opt/docker/entrypoint.sh
RUN chmod 700 /opt/docker/entrypoint.sh

WORKDIR /root/
CMD [ "/opt/docker/entrypoint.sh" ]
