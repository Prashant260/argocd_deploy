# Jenkins Setup

This Jenkins job builds the GitHub self-hosted runner image and pushes it to JFrog Artifactory.

## Jenkins Agent Requirements

The Jenkins agent that runs this job needs:

- Docker installed
- Permission to run Docker commands
- Git installed
- Network access to GitHub and JFrog Artifactory
- Trivy installed if `RUN_SECURITY_SCAN` is enabled

## Jenkins Credentials

Create these credentials in Jenkins:

| Credential ID | Type | Example |
| --- | --- | --- |
| `jfrog-registry-url` | Secret text | `artifactory.company.com` |
| `jfrog-credentials` | Username with password | JFrog username and API token |

Use the Docker registry hostname for `jfrog-registry-url`. Do not include the image repository name here.

## Create the Pipeline Job

1. Open Jenkins.
2. Select **New Item**.
3. Choose **Pipeline**.
4. Under **Pipeline**, select **Pipeline script from SCM**.
5. Select **Git**.
6. Add this repository URL.
7. Set branch to `main`.
8. Set script path to `Jenkinsfile`.
9. Save the job.

## Build Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `IMAGE_TAG` | `latest` | Main image tag pushed to JFrog |
| `JFROG_REPO` | `docker-local` | JFrog Docker repository |
| `RUNNER_VERSION` | `2.334.0` | GitHub Actions runner version |
| `RUN_SECURITY_SCAN` | `true` | Runs Trivy if available |

## Expected Image Tags

The pipeline pushes two tags:

```text
artifactory.company.com/docker-local/github-runner:latest
artifactory.company.com/docker-local/github-runner:<git-short-sha>
```

## First Test

Run the Jenkins job with defaults first:

```text
IMAGE_TAG=latest
JFROG_REPO=docker-local
RUNNER_VERSION=2.334.0
RUN_SECURITY_SCAN=true
```

If Trivy is not installed, the scan stage will print a skip message and continue.

## Common Issues

Docker permission error:

```sh
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

JFrog login fails:

- Check `jfrog-registry-url`.
- Check `jfrog-credentials`.
- Make sure the JFrog user has push permission to `JFROG_REPO`.

Image push path is wrong:

- `jfrog-registry-url` should be only the registry host.
- `JFROG_REPO` should be only the Docker repository name.
