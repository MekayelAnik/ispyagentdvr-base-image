# ispyagentdvr-base-image

Base image for [iSpy Agent DVR](https://www.ispyconnect.com/) Docker builds with hardware-accelerated video processing.

This image is not intended for direct use - to run Agent DVR, use the official [`ispysoftware/agentdvr`](https://hub.docker.com/r/ispysoftware/agentdvr) image, which builds on top of it.

## Features

- Debian Trixie Slim base
- VAAPI GPU drivers: AMD (Mesa radeonsi), Intel (iHD + i965), NVIDIA (nvidia-vaapi-driver)
- VLC media framework
- Multi-architecture: `linux/amd64`, `linux/arm64`, `linux/arm/v7`

FFmpeg is no longer installed in this image: the Agent DVR application package bundles its own FFmpeg (LGPL) build, and the optional GPL build is downloaded by the app on demand at runtime.

## Available Tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest successful build |
| `trixie-slim-vlc` | Rolling variant tag |
| `trixie-slim-vlc-DDMMYYYY` | Date-stamped build |

## Usage

```bash
docker pull ispysoftware/agentdvr-base-image:latest
```

## Upstream Sources

This image tracks one upstream source for new releases:

| Component | Source |
|-----------|--------|
| Debian | `debian:trixie-slim` |

A new image build is triggered automatically when the Debian base image publishes a new digest, with a periodic package-refresh rebuild as a safety net so security updates to build-time packages (GPU drivers, VLC) also reach the image. GPU VAAPI drivers are installed from Debian packages at image build time.

## Registries

- **Docker Hub:** [`ispysoftware/agentdvr-base-image`](https://hub.docker.com/r/ispysoftware/agentdvr-base-image)
- **GHCR:** `ghcr.io/ispysoftware/agentdvr-base-image`

## Pipeline

Automated CI/CD pipeline monitors the upstream base image via external cron trigger (`repository_dispatch`). Builds are multi-arch with ZSTD compression, dual-registry push, and Trivy security scanning.

Manual triggers available via `workflow_dispatch` with options for forced builds and registry selection.

## Credits

Based on the community base image originally created by [MD. Mekayel Anik](https://github.com/MekayelAnik).
