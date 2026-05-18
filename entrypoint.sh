#!/usr/bin/env bash
set -e

RUNNER_DIR="/actions-runner"
RUNNER_USER="runner"
WORK_DIR="${RUNNER_WORKDIR:-/home/runner/_work}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-linux,x64,docker,jfrog}"

cd "${RUNNER_DIR}"

# This helps the runner user access the mounted Docker socket.
if [ -S /var/run/docker.sock ]; then
  DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
  DOCKER_GROUP=$(getent group "${DOCKER_GID}" | cut -d: -f1 || true)

  if [ -z "${DOCKER_GROUP}" ]; then
    groupadd -g "${DOCKER_GID}" docker-host
    DOCKER_GROUP="docker-host"
  fi

  usermod -aG "${DOCKER_GROUP}" "${RUNNER_USER}"
fi

mkdir -p "${WORK_DIR}"
chown -R "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_DIR}" "${WORK_DIR}"

if [ -z "${GITHUB_REPOSITORY}" ]; then
  echo "Please set GITHUB_REPOSITORY like owner/repo"
  exit 1
fi

if echo "${GITHUB_REPOSITORY}" | grep -q '^https://'; then
  echo "GITHUB_REPOSITORY should be owner/repo, not a full URL"
  echo "Example: GITHUB_REPOSITORY=Prashant260/argocd_deploy"
  exit 1
fi

if [ -z "${GITHUB_TOKEN}" ]; then
  echo "Please set GITHUB_TOKEN"
  exit 1
fi

RUNNER_URL="https://github.com/${GITHUB_REPOSITORY}"

echo "Getting runner registration token from GitHub"
API_RESPONSE=$(curl -sX POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token")

REG_TOKEN=$(echo "${API_RESPONSE}" | jq -r .token)

if [ -z "${REG_TOKEN}" ] || [ "${REG_TOKEN}" = "null" ]; then
  echo "Could not get runner token"
  echo "GitHub API response:"
  echo "${API_RESPONSE}" | jq .
  exit 1
fi

remove_runner() {
  echo "Removing runner from GitHub"
  runuser -u "${RUNNER_USER}" -- ./config.sh remove --unattended --token "${REG_TOKEN}" || true
}

trap remove_runner EXIT INT TERM

echo "Configuring runner ${RUNNER_NAME}"
runuser -u "${RUNNER_USER}" -- ./config.sh \
  --url "${RUNNER_URL}" \
  --token "${REG_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}" \
  --work "${WORK_DIR}" \
  --unattended \
  --replace

echo "Starting runner"
runuser -u "${RUNNER_USER}" -- ./run.sh
