# Multi-Container Image Repository

This repository contains definitions for multiple minimal container images, built and published to GitHub Container Registry (GHCR) using Chiseled Ubuntu bases for security and minimalism.

## Containers

### gostatic
A minimal container image based on Chiseled Ubuntu, designed for static applications and Go binaries that don't require additional system libraries.

- **Dockerfile**: `gostatic/Dockerfile`
- **Base**: Chiseled Ubuntu 25.10 with essential system files only
- **Default repository**: `ghcr.io/casualjim/gostatic`
- **Default tag**: `latest`
- **User**: `ubuntu` (non-root)
- **Includes**: Base files, CA certificates, timezone data, media types

### golibc
A minimal container image based on Chiseled Ubuntu with C++ standard library support, suitable for applications requiring `libstdc++6`.

- **Dockerfile**: `golibc/Dockerfile`
- **Base**: Chiseled Ubuntu 25.10 with C++ standard library
- **Default repository**: `ghcr.io/casualjim/golibc`
- **Default tag**: `latest`
- **User**: `ubuntu` (non-root)
- **Includes**: Everything from gostatic + `libstdc++6_libs`

## Customization

Each container can have optional files for customization:

- **`REPO`**: Specify the full repository URL (e.g., `ghcr.io/casualjim/myimage`). If not present, defaults to `ghcr.io/casualjim/{containerName}`.
- **`TAG`**: Specify the image tag (e.g., `v1.0`). If not present, defaults to `latest`.

Place these files in the container's directory (e.g., `gostatic/REPO`).

## Workflow

The GitHub Actions workflow (`.github/workflows/build.yml`) builds and pushes images on:
- Push to the `main` branch
- Every Wednesday at 5PM UTC

The workflow automatically detects all subdirectories with a `Dockerfile` and builds them.

## Adding New Containers

1. Create a new directory with a `Dockerfile`.
2. Optionally add `REPO` and/or `TAG` files for customization.
3. The workflow will automatically detect and build it on the next trigger.
