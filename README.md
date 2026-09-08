# libvirtd-container

Single-container **libvirtd (KVM/QEMU)** image for integration testing in
[`go-docker-testsuite`](https://github.com/teran/go-docker-testsuite).

The container runs `libvirtd` listening on **TCP (16509)** with authentication
disabled, so tests connect with a `go-libvirt` client over TCP and drive the
full libvirt API — virtual machine lifecycle, storage pools/volumes, virtual
networks, snapshots, and more.

## Features

- **TCP by default** — `listen_tcp = 1`, `auth_tcp = "none"`, `listen_addr = 0.0.0.0`.
- **QEMU** for the target architecture (x86_64 or arm64).
- **KVM-ready** — pass `/dev/kvm` through at runtime for hardware
  acceleration; falls back to software (TCG) emulation when absent.
- **Multi-arch** — published for `linux/amd64` and `linux/arm64`.

## Build

```sh
# Single arch
docker build -t libvirtd:latest .

# Multi-arch (amd64 + arm64)
docker buildx build --platform linux/amd64,linux/arm64 -t libvirtd:latest .
```

## Run

```sh
# KVM acceleration (requires a host with /dev/kvm):
docker run --rm -p 16509:16509 --privileged \
  --device /dev/kvm --device /dev/net/tun libvirtd:latest

# Software (TCG) emulation, no /dev/kvm needed:
docker run --rm -p 16509:16509 --cap-add NET_ADMIN \
  --security-opt seccomp=unconfined libvirtd:latest
```

Wait for readiness: libvirtd accepts connections on `16509/tcp`. Connect with
a libvirt client, e.g.:

```sh
virsh -c qemu+tcp://localhost:16509/system list --all
```

## Published image

Tags are published on release to:

```text
ghcr.io/teran/libvirtd-container/libvirtd:<version>
```

## Project docs

- [SPEC.md](./SPEC.md) — architecture and design specification
- [AGENTS.md](./AGENTS.md) — agent instructions for AI-assisted development

## License

[Apache License, Version 2.0](LICENSE)
