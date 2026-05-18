# GitHub Self-Hosted Runner Image

This repo builds a Docker image for a GitHub self-hosted runner. Jenkins builds the image, scans it if Trivy is installed, and pushes it to JFrog Artifactory.

## Flow

```text
GitHub repo
  |
Jenkins pipeline
  |
Docker build
  |
Trivy scan
  |
Push image to JFrog
```

## Files

- `Dockerfile` - builds the runner image
- `entrypoint.sh` - registers and starts the GitHub runner
- `Jenkinsfile` - builds and pushes the image
- `docker-compose.yml` - local testing setup
- `.env.example` - example local environment file

## Tools Installed in the Image

- Git
- Docker CLI
- Node.js and npm
- Python 3 and pip
- kubectl
- Helm
- Argo CD CLI
- jq, curl, wget, unzip

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
GITHUB_TOKEN=your_github_token
```

Start the runner:

```sh
docker compose up
```

## Jenkins Setup

Create these Jenkins credentials:

- `jfrog-registry-url` - example: `artifactory.company.com`
- `jfrog-credentials` - username/password or API token

Create a Jenkins Pipeline job and point it to this repo. Use `Jenkinsfile` as the script path.

## Jenkins Parameters

- `IMAGE_TAG` - image tag, default is `latest`
- `JFROG_REPO` - Artifactory Docker repo, default is `docker-local`

## Run Image Manually

```sh
docker run --rm \
  --name github-runner \
  -e GITHUB_REPOSITORY=owner/repo \
  -e GITHUB_TOKEN=your_github_token \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v runner-work:/home/runner/_work \
  artifactory.company.com/docker-local/github-runner:latest
```

## Notes

- The runner process runs as the `runner` user.
- The container needs the Docker socket if workflows build Docker images.
- Keep `RUNNER_VERSION` in the Dockerfile updated.
- Keep GitHub and JFrog tokens in secrets, not in the repo.
