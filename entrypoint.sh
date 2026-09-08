#!/bin/bash
# Entrypoint for the libvirtd test container: starts the supporting daemons
# (virtlogd, virtlockd) and then libvirtd in the foreground, listening on TCP
# (16509) per the injected libvirtd.conf.
#
# Logs go to stdout/stderr so `docker logs` shows libvirtd startup output.
set -euo pipefail

mkdir -p /run/libvirt

# On cgroup v2, libvirt (without systemd) manages VM processes under a
# "machine" cgroup at /sys/fs/cgroup/machine. Ensure it exists so launching a
# VM can create its qemu-<id>-<name>.libvirt-qemu scope underneath. Best-effort:
# some Docker setups (e.g. Desktop on macOS) expose /sys/fs/cgroup read-only.
mkdir -p /sys/fs/cgroup/machine 2>/dev/null || true

# virtlogd and virtlockd must be running before libvirtd. They daemonize;
# tolerate failures so a stale socket does not abort the entrypoint.
/usr/sbin/virtlogd -d 2>/dev/null || true
/usr/sbin/virtlockd -d 2>/dev/null || true
sleep 1

# --listen makes libvirtd bind the TCP socket itself (no systemd socket
# activation needed inside the container).
exec /usr/sbin/libvirtd --listen
