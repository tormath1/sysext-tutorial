# Hands-on 1: Use a sysext with wasmtime on Flatcar Container Linux

[![asciicast](https://asciinema.org/a/706911.svg)](https://asciinema.org/a/706911)

## Setting up a Flatcar Container Linux virtual machine

For this hands on, we will be using a Flatcar system.

If you are attending KubeCon London, you can connect to the lab system via SSH
and then create a Flatcar virtual machine using the command `launch_flatcar`:

```
$ ssh labuserX@WW.XX.YY.ZZ
...
labuserX@sysext-lab:~$ launch_flatcar
```

The password for the `core` user is `core`.

Otherwise, you can provision a system on any platform, using the
[documentation](https://www.flatcar.org/docs/latest/installing/).

## Getting the system extension

Let's first download a simple sysext image that includes
[`wastime`](https://wasmtime.dev/):

```bash
wget https://github.com/flatcar/sysext-bakery/releases/download/latest/wasmtime-24.0.0-x86-64.raw
```

## Inspecting its content

Before merging the system extension with the system, we can inspect the content
of the image:

```
sudo systemd-dissect wasmtime-24.0.0-x86-64.raw --list
```

## Setting up the system extension

Now we can move the image into `/var/lib/extensions` so that it will be taken
into account by `systemd-sysext`:

```
sudo install -d -m 0755 -o 0 -g 0 -Z /var/lib/extensions
sudo mv wasmtime-24.0.0-x86-64.raw /etc/extensions/wasmtime.raw
```

:warning: The name of the image must match the name the extension name (i.e the
suffix here: `/usr/lib/extension-release.d/extension-release.wasmtime`)

## Merging the system extension

It is now possible to merge the extensions:

```
sudo systemd-sysext merge
systemd-sysext status
```

## Testing out wasmtime

```
wasmtime --version
```

## Resources

* [systemd-sysext man page on man7.org](https://man7.org/linux/man-pages/man8/systemd-sysext.8.html)
* [systemd-sysext man page on fdo.org](https://www.freedesktop.org/software/systemd/man/latest/systemd-sysext.html)
