#!/bin/bash
set -euo pipefail

# Cleanup any leftovers
sudo rm -fr ./*.rpm ./rootfs ./crio*.raw

echo "Downloading cri-o & cri-tools RPMs"
dnf download --resolve cri-o1.32 cri-tools1.32

# Prepare sysext folder to unpack the RPMs
mkdir -p rootfs

echo "Extracting RPMs into a temporary location"
cd rootfs
for rpm in ../*.rpm; do
    rpm2cpio "$rpm" | sudo cpio -idmv &> /dev/null || true
done

echo "Moving default config from /etc to /usr/etc"
sudo mv etc usr

echo "Setting up systemd configuration to start the service on boot"
sudo install -d -m 0755 -o 0 -g 0 usr/lib/systemd/system/multi-user.target.d
{
echo "[Unit]"
echo "Upholds=crio.service"
} | sudo tee "usr/lib/systemd/system/multi-user.target.d/crio.conf"

echo "Setting up systemd system extension config file"
sudo install -d -m0755 usr/lib/extension-release.d
{
echo "ID=_any"
echo "ARCHITECTURE=x86-64"
echo "EXTENSION_RELOAD_MANAGER=1"
} | sudo tee "usr/lib/extension-release.d/extension-release.crio"

echo "Resetting SELinux contexts"
sudo setfiles -r . "/etc/selinux/targeted/contexts/files/file_contexts" .
sudo chcon --user=system_u --recursive .

cd ..

echo "Creating a squashFS image"
mksquashfs rootfs crio.raw

echo "Done!"
