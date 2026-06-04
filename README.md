# ispyagentdvr-base-image

Base image for [iSpy Agent DVR](https://www.ispyconnect.com/) Docker builds with hardware-accelerated video processing.

## Features

- Debian Trixie Slim base
- Self-contained iSpy FFmpeg with hardware acceleration support
- VAAPI GPU drivers: AMD (Mesa radeonsi), Intel (iHD + i965), NVIDIA (nvidia-vaapi-driver)
- VLC media framework
- Multi-architecture: `linux/amd64`, `linux/arm64`, `linux/arm/v7`

## Available Tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest successful build |
| `trixie-slim-vlc-ispy-ffmpeg-8.1` | Version-pinned rolling tag |
| `trixie-slim-vlc-ispy-ffmpeg-8.1-DDMMYYYY` | Date-stamped build |

## Usage

```bash
docker pull mekayelanik/ispyagentdvr-base-image:latest
```

## Upstream Sources

This image tracks one upstream source for new releases:

| Component | Repository | Current Version |
|-----------|------------|-----------------|
| iSpy FFmpeg | [files.ispyconnect.com](https://files.ispyconnect.com/libs/ffmpeg_version.txt) | 8.1 |

A new image build is triggered automatically when upstream publishes a new release (iSpy FFmpeg prebuilt tarballs must be available for all arches). GPU VAAPI drivers are installed from Debian packages at image build time.

## Registries

- **Docker Hub:** [`mekayelanik/ispyagentdvr-base-image`](https://hub.docker.com/r/mekayelanik/ispyagentdvr-base-image)
- **GHCR:** `ghcr.io/mekayelanik/ispyagentdvr-base-image`

## Pipeline

Automated CI/CD pipeline monitors upstream releases via external cron trigger (`repository_dispatch`). Builds are multi-arch with ZSTD compression, dual-registry push, and Trivy security scanning.

Manual triggers available via `workflow_dispatch` with options for forced builds, version overrides, and registry selection.
