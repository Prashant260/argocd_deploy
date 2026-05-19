# GitHub Self-Hosted Runner Image

This repo builds a Docker image for a GitHub self-hosted runner. Jenkins builds the image and pushes it to JFrog Artifactory.

## Flow

```text
GitHub repo
  |
Jenkins pipeline
  |
Docker build
  |
Push image to JFrog
```

## Files

- `Dockerfile` - builds the runner image
- `start.sh` - registers and starts the GitHub runner
- `entrypoint.sh` - old wrapper that calls `start.sh`
- `Jenkinsfile` - builds and pushes the image
- `docker-compose.yml` - local testing setup
- `.env.example` - example local environment file

## Tools Installed in the Image

- Git
- Docker CLI
- jq
- curl
- sudo
- tar

## Local Build

Build the image:

```sh
docker build -t github-runner:latest .
```

Create local env file:

```sh
cp .env.example .env
```

Update `.env`:

```sh
GITHUB_REPOSITORY=owner/repo
RUNNER_TOKEN=token_from_github_runner_page
```

Start the runner:

```sh
docker compose up
```

If workflow jobs cannot access Docker, set the host Docker group id in `.env`:

```sh
DOCKER_GID=$(getent group docker | cut -d: -f3)
```

## Jenkins Setup

Create these Jenkins credentials:

- `jfrog-registry-url` - example: `artifactory.company.com`
- `jfrog-credentials` - username/password or API token

Create a Jenkins Pipeline job and point it to this repo. Use `Jenkinsfile` as the script path.

More detailed steps are in `docs/jenkins-setup.md`.

## Jenkins Parameters

- `IMAGE_TAG` - image tag, default is `latest`
- `JFROG_REPO` - Artifactory Docker repo, default is `docker-local`
- `RUNNER_VERSION` - GitHub Actions runner version, default is `2.334.0`
- `DOCKER_CLI_VERSION` - Docker CLI version installed in the image, default is `27.5.1`

## Run Image Manually

```sh
docker run --rm \
  --name github-runner \
  -e GITHUB_REPOSITORY=owner/repo \
  -e RUNNER_TOKEN=token_from_github_runner_page \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v runner-work:/home/runner/_work \
  artifactory.company.com/docker-local/github-runner:latest
```

## Notes

- The runner process runs as the `runner` user.
- The image installs the Docker CLI only. It uses the host Docker socket if workflows build Docker images.
- `DOCKER_GID` should match the host Docker group id when using `docker-compose.yml`.
- Use `RUNNER_TOKEN` for the temporary token from GitHub's runner setup page.
- Use `GITHUB_TOKEN` only for a real GitHub PAT, usually starting with `ghp_` or `github_pat_`.
- Keep the Jenkins `RUNNER_VERSION` parameter updated when GitHub releases a new runner.
- Keep GitHub and JFrog tokens in secrets, not in the repo.
