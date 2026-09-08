# libvirtd-container — Specification

## Overview

A single-container **libvirtd (KVM/QEMU)** image for integration testing in
`go-docker-testsuite`. It runs libvirtd listening on TCP (16509) with
authentication disabled, exposing the full libvirt API to test clients
(go-libvirt, virsh).

## Architecture

```text
                 ┌────────────────────────────┐
  go-docker-testsuite  │   libvirtd-container        │
  (go-libvirt client)  │                              │
  ────── TCP 16509 ───▶│  libvirtd --listen          │
                 │   ├─ virtlogd / virtlockd        │
                 │   └─ QEMU (KVM or TCG)           │
                 └────────────────────────────┘
```

### Container runtime

| Component | Purpose |
| --------- | ------- |
| `libvirtd --listen` | Foreground libvirtd, binds TCP 16509 (no systemd) |
| `virtlogd` / `virtlockd` | Supporting daemons libvirtd depends on |
| QEMU | Guest emulation; per-arch install (qemu-kvm / qemu-system-arm) |

### Configuration

- `libvirtd.conf`: `listen_tcp = 1`, `auth_tcp = "none"`,
  `listen_addr = "0.0.0.0"` — TCP with no auth (ephemeral test container).
- `qemu.conf`: `user = "root"`, `group = "root"` — QEMU runs as root so it can
  access `/dev/kvm` when passed through.

### Multi-arch

The Dockerfile installs architecture-appropriate QEMU via `TARGETARCH`; the
release workflow publishes `linux/amd64` and `linux/arm64`.

## Runtime requirements

- **KVM**: pass `/dev/kvm` and `/dev/net/tun` (and usually `--privileged` or
  the `NET_ADMIN` capability) for accelerated VMs and virtual networks.
- **TCG fallback**: without `/dev/kvm`, QEMU runs in software (TCG) emulation —
  slower but functional.

## Security

- **Not production-ready.** `auth_tcp = "none"` and root-run QEMU are
  intentional for ephemeral test containers and documented as such.
- No secrets or credentials are baked into the image.

## CI

- **release.yml** (on tag `v*`): `hadolint`, `markdownlint`, `shellcheck`,
  then buildx multi-arch build + push to GHCR.
