FROM ubuntu:22.04

LABEL maintainer="DevOps Team"

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_VERSION=2.317.0

# Install packages needed by the runner and common CI jobs.
RUN apt-get update && apt-get install -y \
    build-essential \
    ca-certificates \
    curl \
    docker.io \
    git \
    gnupg \
    jq \
    nodejs \
    npm \
    openssh-client \
    python3 \
    python3-pip \
    sudo \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Extra DevOps tools used by our pipelines.
RUN curl -LO "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl" && \
    install -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

RUN curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

RUN curl -sSL -o /usr/local/bin/argocd \
    https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && \
    chmod +x /usr/local/bin/argocd

# Create a normal user for the runner.
RUN useradd -m -s /bin/bash runner && \
    usermod -aG docker,sudo runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner && \
    chmod 0440 /etc/sudoers.d/runner

WORKDIR /actions-runner

# Download and install the GitHub Actions runner.
RUN curl -L -o actions-runner.tar.gz \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    tar xzf actions-runner.tar.gz && \
    rm actions-runner.tar.gz && \
    ./bin/installdependencies.sh && \
    mkdir -p /home/runner/_work && \
    chown -R runner:runner /actions-runner /home/runner

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
