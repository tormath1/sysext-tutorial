# Hands-on 1: Use a sysext with wasmtime on Fedora CoreOS

[![asciicast](https://asciinema.org/a/710119.svg)](https://asciinema.org/a/710119)

## Connecting to the lab system

If you are attending KubeCon London, you can connect to the lab system via SSH:

```
ssh labuserX@WW.XX.YY.ZZ
```

## Setting up a Fedora CoreOS virtual machine

For this hands on, we will be using a Fedora CoreOS system.

If you are attending KubeCon London, you can create a Fedora CoreOS virtual
machine using the command `launch_fcos`:

```
labuserX@sysext-lab:~$ launch_fcos
```

The password for the `core` user is `core`.

Otherwise, you can provision a system on any platform, using the
[documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/).

## Getting the system extension

**Make sure that you are connected to the Fedora CoreOS virtual machine
launched above before moving further.**

Let's first download a simple sysext image that includes
[`wastime`](https://wasmtime.dev/):

```bash
curl -O --location https://github.com/travier/fedora-sysexts/releases/download/fedora-coreos-stable/wasmtime-41.20250302.3.2-x86-64.raw
```

## Inspecting its content

Before merging the system extension with the system, we can inspect the content
of the image:

```
sudo systemd-dissect wasmtime-41.20250302.3.2-x86-64.raw --list
```

## Setting up the system extension

Now we can move the image into `/var/lib/extensions` so that it will be taken
into account by `systemd-sysext`:

```
sudo install -d -m 0755 -o 0 -g 0 -Z /var/lib/extensions
sudo mv wasmtime-41.20250302.3.2-x86-64.raw /var/lib/extensions/wasmtime.raw
```

:warning: The name of the image must match the name the extension name (i.e the
suffix here: `/usr/lib/extension-release.d/extension-release.wasmtime`)

## Merging the system extension

It is now possible to merge the extensions:

```
sudo systemctl restart systemd-sysext.service
systemd-sysext status
```

:warning: We can not use `sudo systemd-sysext merge` directly here as there is
an incompatibility between systemd and SELinux that is fixed in systemd v257
only.

## Testing out wasmtime

Let's make sure that `wasmtime` is now available:

```
wasmtime --version
```

Then let's get an example WASI application and run it with `wasmtime`:

```
$ curl -O --location https://github.com/tormath1/sysext-tutorial/raw/refs/heads/main/hands-on-1/wasi_hello_world.wasm
$ mkdir helloworld
$ wasmtime run --dir=$PWD::/ wasi_hello_world.wasm
Hello KubeCon London 2025!
$ cat helloworld/helloworld.txt
Hello KubeCon London 2025!
```

## Wrapping up the hands on

If you are attending KubeCon London, you can exit the Virtual Machine
by shutting it down:

```
sudo poweroff
```

Or by disconnecting from the console with `Ctrl + ]` and then destroying the
virtual machine:

```
# Get the name of the virtual machine
virsh list
virsh destroy fcos-labuserX
```

## Resources

* [systemd-sysext man page on man7.org](https://man7.org/linux/man-pages/man8/systemd-sysext.8.html)
* [systemd-sysext man page on fdo.org](https://www.freedesktop.org/software/systemd/man/latest/systemd-sysext.html)
