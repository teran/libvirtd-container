# syntax=docker/dockerfile:1
#
# libvirtd (KVM/QEMU) single-container image for integration testing in
# go-docker-testsuite.
#
# The container runs libvirtd listening on TCP (16509) with authentication
# disabled, so tests connect with a go-libvirt client over TCP. QEMU is
# installed for the target architecture; /dev/kvm is passed through at runtime
# for KVM acceleration (falls back to TCG software emulation when absent).
#
# Build (single arch):
#   docker build -t libvirtd:latest .
#
# Build (multi-arch amd64 + arm64):
#   docker buildx build --platform linux/amd64,linux/arm64 -t libvirtd:latest .
#
# Run (KVM acceleration; requires a host with /dev/kvm):
#   docker run --rm -p 16509:16509 --privileged \
#     --device /dev/kvm --device /dev/net/tun libvirtd:latest
#
# Run (software/TCG emulation, no /dev/kvm required):
#   docker run --rm -p 16509:16509 --cap-add NET_ADMIN \
#     --security-opt seccomp=unconfined libvirtd:latest
#
# Wait for readiness: libvirtd starts and accepts connections on 16509/tcp.

ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ARG TARGETARCH

# Install libvirtd and the QEMU emulator for the target architecture.
# The packages below are available in Ubuntu's main/universe and are
# multi-arch safe; QEMU differs per architecture.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libvirt-daemon-system \
        libvirt-clients \
        qemu-utils \
        dnsmasq \
        iptables \
        iproute2 \
        netcat-openbsd \
    && if [ "${TARGETARCH}" = "arm64" ]; then \
           apt-get install -y --no-install-recommends \
               qemu-system-arm qemu-efi-aarch64; \
       else \
           apt-get install -y --no-install-recommends \
               qemu-kvm ovmf; \
       fi \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable TCP listening without authentication for ephemeral test containers.
# listen_tls must stay 0: libvirtd aborts if it tries to set up TLS without a
# CA certificate, and we only need the plain TCP (16509) endpoint.
RUN printf 'listen_tcp = 1\nlisten_tls = 0\nauth_tcp = "none"\nlisten_addr = "0.0.0.0"\n' \
    >> /etc/libvirt/libvirtd.conf

# Run VMs as root inside the container so KVM (/dev/kvm) is reachable by QEMU
# without additional user/group setup. Acceptable for a throwaway test image.
RUN printf 'user = "root"\ngroup = "root"\n' >> /etc/libvirt/qemu.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 16509/tcp

ENTRYPOINT ["/entrypoint.sh"]
