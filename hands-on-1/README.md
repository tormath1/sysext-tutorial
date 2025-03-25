# Hands-on 1: Merge a simple sysext on Fedora CoreOS

Let's first download a simple sysext image that ships [`wastime`](https://wasmtime.dev/):

```bash
wget https://github.com/travier/fedora-sysexts/releases/download/fedora-coreos-stable/wasmtime-41.20250302.3.2-x86-64.raw
```

Before merging, we can inspect the content of the image:
```
sudo systemd-dissect wasmtime-41.20250302.3.2-x86-64.raw --list
```

Now we can move the image into `/var/lib/extensions`.
:warning: The name of the image must match the name the extension name (i.e the suffix here: `usr/lib/extension-release.d/extension-release.gdb`)

```
$ sudo install -d -m 0755 -o 0 -g 0 -Z /var/lib/extensions
$ sudo mv wasmtime-41.20250302.3.2-x86-64.raw /var/lib/extensions/wasmtime.raw
```

It is now possible to merge the extensions:

```
sudo systemctl restart systemd-sysext.service
wasmtime --version
systemd-sysext status
```

Note: We can not use `sudo systemd-sysext merge` directly here as there is an issue in systemd/SELinux that is fixed in v257 only.

Resources:
* https://man7.org/linux/man-pages/man8/systemd-sysext.8.html
* https://www.freedesktop.org/software/systemd/man/latest/systemd-sysext.html
