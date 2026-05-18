FROM ubuntu:22.04

ARG RUNNER_VERSION=2.334.0

RUN apt-get update && apt-get install -y \
    curl \
    docker.io \
    git \
    jq \
    sudo \
    tar \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m runner \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/runner

RUN curl -fsSL -o actions-runner-linux-x64.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    && tar xzf actions-runner-linux-x64.tar.gz \
    && rm actions-runner-linux-x64.tar.gz \
    && ./bin/installdependencies.sh

COPY start.sh /home/runner/start.sh

RUN chmod +x /home/runner/start.sh \
    && chown -R runner:runner /home/runner

USER runner

ENTRYPOINT ["/home/runner/start.sh"]
