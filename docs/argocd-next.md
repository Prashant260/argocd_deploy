# Argo CD Next Step

After Jenkins can build and push the runner image to JFrog, the next step is deciding what Argo CD should deploy.

## What Argo CD Usually Needs

Argo CD needs a Kubernetes manifest, Kustomize folder, or Helm chart. This runner image repo currently only builds the image, so there are two common options:

## Option 1: Keep Deployment in Another Repo

Use this repo only for the image build.

Use a separate deployment repo for Kubernetes manifests:

```text
deployment-repo/
  github-runner/
    deployment.yaml
    service-account.yaml
    secret.yaml
    kustomization.yaml
```

Argo CD watches that deployment repo.

## Option 2: Add Kubernetes Manifests Here

Add a `k8s/` folder in this repo:

```text
k8s/
  deployment.yaml
  secret.example.yaml
  kustomization.yaml
```

Argo CD watches this repo and deploys from `k8s/`.

## Recommendation

For now, use Option 1 if this is meant to be an image/infrastructure repo. It keeps Jenkins image builds separate from Kubernetes deployment config.

## Information Needed Before Creating Argo CD Manifests

- Kubernetes namespace
- JFrog image URL after Jenkins push
- Whether the runner should be repo-level or org-level
- How secrets will be stored in Kubernetes
- Whether Docker socket access is required in the Kubernetes runner pod
