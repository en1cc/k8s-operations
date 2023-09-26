# PRE-BUILD ARGS
ARG UBUNTU_VERSION=22.04

# BUILDER IMAGE
FROM ubuntu:${UBUNTU_VERSION} as BUILDER

# BUILD ARGS
ARG ARCH=amd64
ARG KUBECTL_VERSION=1.26.8
ARG HELMFILE_VERSION=0.144.0
ARG HELM_VERSION=3.12.3
ARG HELM_DIFF_VERSION=3.8.1
ARG HELM_SECRETS_VERSION=4.5.1
ARG HELM_S3_VERSION=0.15.1
ARG HELM_GIT_VERSION=0.15.1


RUN apt update && \
    apt install -y git curl

ADD https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz /tmp
RUN tar -zxvf /tmp/helm* -C /tmp && \
    mv /tmp/linux-${ARCH}/helm /usr/bin/helm && \
    rm -rf /tmp/*
RUN helm version

RUN helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION} && \
    helm plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_SECRETS_VERSION} && \
    helm plugin install https://github.com/hypnoglow/helm-s3.git --version ${HELM_S3_VERSION} && \
    helm plugin install https://github.com/aslafy-z/helm-git --version ${HELM_GIT_VERSION}

ADD https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_${ARCH}.tar.gz /tmp
RUN tar -zxvf /tmp/helmfile* -C /tmp && \
    install -o root -g root -m 0755 /tmp/helmfile /usr/bin/helmfile && \
    rm -rf /tmp/*
RUN helmfile version

ADD https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl /tmp/kubectl
RUN install -o root -g root -m 0755 /tmp/kubectl /usr/bin/kubectl &&\
    rm -rf /tmp/*
RUN kubectl version --client=true --short

# FINAL STAGE
FROM ubuntu:${UBUNTU_VERSION}

RUN apt update && \
    apt install -y curl

COPY --from=BUILDER /usr/bin/helm /usr/bin/helm
COPY --from=BUILDER /root/.local/share/helm/plugins /root/.local/share/helm/plugins
COPY --from=BUILDER /usr/bin/curl /usr/bin/curl
COPY --from=BUILDER /usr/bin/git /usr/bin/git
COPY --from=BUILDER /usr/bin/helmfile /usr/bin/helmfile
COPY --from=BUILDER /usr/bin/kubectl /usr/bin/kubectl

# LABELS
LABEL org.opencontainers.image.vendor="Patrick Spittelmeister"
LABEL org.opencontainers.image.authors="mail@spittelmeister.net"