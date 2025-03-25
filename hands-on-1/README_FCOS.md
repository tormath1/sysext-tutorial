# Hands-on 1: Merge a simple sysext

Let's first download a simple sysext image that ships `gdb`:

```bash
wget https://github.com/travier/fedora-sysexts/releases/download/fedora-coreos-stable/gdb-41.20250302.3.2-x86-64.raw
```

Before merging, we can inspect the content of the image:
```
sudo systemd-dissect gdb-41.20250302.3.2-x86-64.raw --list
```

Now we can move the image into `/var/lib/extensions`.
:warning: The name of the image must match the name the extension name (i.e the suffix here: `usr/lib/extension-release.d/extension-release.gdb`)

```
$ sudo install -d -m 0755 -o 0 -g 0 -Z /var/lib/extensions
$ sudo mv gdb-41.20250302.3.2-x86-64.raw /var/lib/extensions/gdb.raw
```

It is now possible to merge the extensions:

```
sudo systemctl restart systemd-sysext.service
systemd-sysext status
gdb --version
systemd-sysext status
```

Resources:
* https://man7.org/linux/man-pages/man8/systemd-sysext.8.html
* https://www.freedesktop.org/software/systemd/man/latest/systemd-sysext.html
