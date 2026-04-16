# OS Installation Methods

## Cloud Image (Quickest)

Write a cloud image directly to the target
partition. See the `/cloud-image` skill for
post-deployment steps (SSH keys, cloud-init,
network configuration).

**Best when:** the target filesystem does not need
to be accessed from the existing OS during setup.

## debootstrap in QEMU (Cleanest)

Boot a minimal Linux environment (e.g. via QEMU or
rescue mode), mount the target partition, and use
`debootstrap` to install a minimal Debian/Ubuntu
system.

**Best when:** FreeBSD is the existing OS and
cannot mount the target ext4 filesystem, or when
fine-grained control over the installation is
needed.

## Network Install (Interactive)

Boot from an ISO and run the standard OS installer.
Hard to automate but familiar to most users.

**Best when:** the user prefers the standard
installer experience.
