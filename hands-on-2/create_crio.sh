#!/bin/bash
set -euo pipefail

SYSEXTNAME="crio"
ARCH="amd64"
VERSION="v1.32.2"

# Cleanup any leftovers.
rm -fr "cri-o.${ARCH}.${VERSION}.tar.gz" "${SYSEXTNAME}" "${SYSEXTNAME}".raw

# Download CRI-O release.
echo Downloading CRI-O "${VERSION}"
curl -o "cri-o.${ARCH}.${VERSION}.tar.gz" -fsSL "https://storage.googleapis.com/cri-o/artifacts/cri-o.${ARCH}.${VERSION}.tar.gz"

# Prepare sysext folder to unpack the CRI-O release.
mkdir -p "${SYSEXTNAME}" "${SYSEXTNAME}/tmp"

# Install CRI-O into the future sysext.
echo Installing CRI-O "${VERSION}" into a temporary location
tar --force-local -xf "cri-o.${ARCH}.${VERSION}.tar.gz" -C "${SYSEXTNAME}/tmp"
cd "${SYSEXTNAME}/tmp/cri-o/"

# Removes sed replacements from install script to keep the default location
# (/usr) in the base config file
sed -i '/^sed -i.*DESTDIR/d' install

DESTDIR="${PWD}/../../../${SYSEXTNAME}" \
    PREFIX=/usr \
    ETCDIR=$PREFIX/share/crio/etc \
    OCIDIR=$PREFIX/share/oci-umount/oci-umount.d \
    CNIDIR=$PREFIX/share/crio/cni/etc/net.d/ \
    OPT_CNI_BIN_DIR=$PREFIX/share/crio/cni/bin/ \
    BASHINSTALLDIR=/tmp \
    FISHINSTALLDIR=/tmp \
    ZSHINSTALLDIR=/tmp \
    MANDIR=/tmp \
    ./install
cd -
rm -rf "${SYSEXTNAME}/tmp"

# Move systemd unit from /etc to /usr
mkdir -p "${SYSEXTNAME}"/usr/lib/systemd/system
mv "${SYSEXTNAME}"/etc/systemd/system/crio.service \
    "${SYSEXTNAME}"/usr/lib/systemd/system/crio.service
rm -rf "${SYSEXTNAME}"/etc

# Create some configuration for CRI-O (can be set via Ignition too)
echo Generating CRI-O "${VERSION}" default configuration
cat > "${SYSEXTNAME}"/usr/share/crio/etc/crio/crio.conf <<'EOF'
# /etc/crio/crio.conf - Configuration file for crio
# See /etc/crio/crio.conf.d/ for additional config files
EOF

# Create the Systemd unit and configuration files
echo Generating CRI-O "${VERSION}" systemd configuration
mkdir -p "${SYSEXTNAME}"/usr/lib/systemd/system/crio.service.d
cat > "${SYSEXTNAME}"/usr/lib/systemd/system/crio.service.d/10-crio.conf <<-'EOF'
[Service]
Environment="CONTAINER_CNI_PLUGIN_DIR=/opt/cni/bin"
Environment="CONTAINER_CONFIG=/etc/crio/crio.conf"
Environment="CONTAINER_CNI_CONFIG_DIR=/etc/cni/net.d"
ExecStartPre=/usr/bin/mkdir -p /opt/cni/bin /etc/crio/crio.conf.d/ /etc/cni/net.d/ /var/log/crio
ExecStartPre=/usr/bin/rsync -ur /usr/share/crio/etc/ /etc/
ExecStart=
ExecStart=/usr/bin/crio --config-dir /etc/crio/crio.conf.d/ \
          $CRIO_CONFIG_OPTIONS \
          $CRIO_RUNTIME_OPTIONS \
          $CRIO_STORAGE_OPTIONS \
          $CRIO_NETWORK_OPTIONS \
          $CRIO_METRICS_OPTIONS
EOF

mkdir -p "${SYSEXTNAME}"/usr/lib/systemd/system/multi-user.target.d
# This is required to run `crio.service` once the sysext image is loaded.
{ echo "[Unit]"; echo "Upholds=crio.service"; } > "${SYSEXTNAME}"/usr/lib/systemd/system/multi-user.target.d/10-crio.conf

# This is the configuration of the sysext itself
echo Generating CRI-O "${VERSION}" sysext identity
mkdir -p "${SYSEXTNAME}/usr/lib/extension-release.d"
cat > "${SYSEXTNAME}/usr/lib/extension-release.d/extension-release.${SYSEXTNAME}" <<-'EOF'
ID=_any
ARCHITECTURE=x86-64
EXTENSION_RELOAD_MANAGER=1
EOF

# Package the directory as a squashFS image
mksquashfs "${SYSEXTNAME}" "${SYSEXTNAME}".raw -xattrs-exclude '^btrfs.'
rm -fr "cri-o.${ARCH}.${VERSION}.tar.gz" "${SYSEXTNAME}"
echo CRI-O "${VERSION}" sysext image generated: "${SYSEXTNAME}".raw
