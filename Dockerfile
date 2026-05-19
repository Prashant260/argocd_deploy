FROM ubuntu:22.04

ARG RUNNER_VERSION=2.334.0
ARG DOCKER_CLI_VERSION=27.5.1

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    jq \
    sudo \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Install only the Docker CLI. The runner uses the host Docker socket,
# so this image does not need to run a Docker daemon.
RUN curl -fsSL -o docker.tgz \
    "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz" \
    && tar xzf docker.tgz --strip-components=1 docker/docker \
    && mv docker /usr/local/bin/docker \
    && rm docker.tgz

RUN useradd -m runner \
    && groupadd docker \
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
