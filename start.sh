#!/usr/bin/env bash
set -e

RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-linux,x64,docker,jfrog}"
WORK_DIR="${RUNNER_WORKDIR:-/home/runner/_work}"

echo "Starting GitHub runner setup"

if [ -z "${GITHUB_REPOSITORY:-}" ]; then
  echo "Please set GITHUB_REPOSITORY like owner/repo"
  exit 1
fi

if echo "${GITHUB_REPOSITORY}" | grep -q '^https://'; then
  echo "GITHUB_REPOSITORY should be owner/repo, not a full URL"
  echo "Example: GITHUB_REPOSITORY=Prashant260/argocd_deploy"
  exit 1
fi

RUNNER_URL="https://github.com/${GITHUB_REPOSITORY}"

if [ -n "${RUNNER_TOKEN:-}" ]; then
  echo "Using token from RUNNER_TOKEN"
  REG_TOKEN="${RUNNER_TOKEN}"
elif [ -n "${GITHUB_TOKEN:-}" ]; then
  if echo "${GITHUB_TOKEN}" | grep -Eq '^(ghp_|github_pat_)'; then
    echo "Getting runner registration token from GitHub PAT"
    API_RESPONSE=$(curl -sX POST \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token")

    REG_TOKEN=$(echo "${API_RESPONSE}" | jq -r .token)

    if [ -z "${REG_TOKEN}" ] || [ "${REG_TOKEN}" = "null" ]; then
      echo "Could not get runner token"
      echo "GitHub API response:"
      echo "${API_RESPONSE}" | jq .
      exit 1
    fi
  else
    echo "GITHUB_TOKEN does not look like a PAT, using it as the runner token"
    REG_TOKEN="${GITHUB_TOKEN}"
  fi
else
  echo "Please set RUNNER_TOKEN or GITHUB_TOKEN"
  exit 1
fi

mkdir -p "${WORK_DIR}"

cleanup() {
  echo "Removing runner from GitHub"
  ./config.sh remove --unattended --token "${REG_TOKEN}" || true
}

trap cleanup EXIT INT TERM

echo "Configuring runner ${RUNNER_NAME}"
./config.sh \
  --url "${RUNNER_URL}" \
  --token "${REG_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}" \
  --work "${WORK_DIR}" \
  --unattended \
  --replace

echo "Runner configured, starting now"
./run.sh
