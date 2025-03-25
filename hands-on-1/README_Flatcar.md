# Hands-on 1: Merge a simple sysext

[![asciicast](https://asciinema.org/a/706911.svg)](https://asciinema.org/a/706911)

Let's first download a simple sysext image that ships [`wasmtime`](https://wasmtime.dev/) environment.

```bash
wget https://github.com/flatcar/sysext-bakery/releases/download/latest/wasmtime-24.0.0-x86-64.raw
```

Before merging, we can inspect the content of the image:
```
sudo systemd-dissect wasmtime-24.0.0-x86-64.raw --list
```

Now we can move the image into `/etc/extensions`.
:warning: The name of the image must match the name the extension name (i.e the suffix here: `usr/lib/extension-release.d/extension-release.wasmtime`)

```
sudo mv wasmtime-24.0.0-x86-64.raw /etc/extensions/wasmtime.raw
```

It is now possible to merge the extensions:
```
sudo systemd-sysext merge
wasmtime --version
systemd-sysext status
```

Resources:
* https://man7.org/linux/man-pages/man8/systemd-sysext.8.html
* https://www.freedesktop.org/software/systemd/man/latest/systemd-sysext.html
