# Agent Instructions for libvirtd-container

## Project identity

This repository builds a single-container **libvirtd (KVM/QEMU)** image used
for integration testing in `go-docker-testsuite`. The image runs libvirtd
listening on TCP (16509) with authentication disabled.

## Language

All communication (code, comments, commit messages, documentation, discussion)
must be in **English**.

## Conventions

1. **Shell**: `entrypoint.sh` must pass `shellcheck` and use `set -euo pipefail`.
2. **Dockerfile**: must pass `hadolint`. Keep it multi-arch (amd64 + arm64)
   via `TARGETARCH`-conditional package installs. No secrets baked in.
3. **Markdown**: all `.md` files must pass `markdownlint`.
4. **Security**: the image is test-only — `auth_tcp = "none"` and root-run QEMU
   are intentional and documented. Do not claim production readiness.
5. **Do not introduce secrets or credentials.**

## Project structure

```text
./
├── Dockerfile            # Ubuntu base, libvirt + QEMU, TCP config
├── entrypoint.sh         # virtlogd/virtlockd + libvirtd --listen foreground
├── README.md             # Usage, build, run
├── SPEC.md               # Architecture specification
└── .github/workflows/
    └── release.yml       # Lint + buildx multi-arch publish to GHCR
```

## Release

Tags of the form `v*` trigger the release workflow, which publishes
`ghcr.io/teran/libvirtd-container/libvirtd:<tag>` for `linux/amd64` and
`linux/arm64`.

## When agents should ask

- If a change would introduce a new base image or major new dependency — ask.
- If a change would enable authentication or a production-facing feature — ask.
