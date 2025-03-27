# Hands-on 1: Use a sysext with wasmtime on Flatcar Container Linux

[![asciicast](https://asciinema.org/a/706911.svg)](https://asciinema.org/a/706911)

## Connecting to the lab system

If you are attending KubeCon London, you can connect to the lab system via SSH:

```
ssh labuserX@WW.XX.YY.ZZ
```

## Setting up a Fedora CoreOS virtual machine

For this hands on, we will be using a Flatcar Container Linux system.

You can create a Flatcar Container Linux virtual machine using the command
`launch_flatcar`:

```
labuserX@sysext-lab:~$ launch_flatcar
...
core@flatcar ~ $
```

The password for the `core` user is `core`.

Otherwise, you can provision a system on any platform, using the
[documentation](https://www.flatcar.org/docs/latest/installing/).

## Getting the system extension

**Make sure that you are connected to the Flatcar Container Linux virtual
machine launched above before moving further.**

Let's first download a simple sysext image that includes
[`wastime`](https://wasmtime.dev/):

```bash
core@flatcar ~ $ wget https://github.com/flatcar/sysext-bakery/releases/download/latest/wasmtime-24.0.0-x86-64.raw
```

## Inspecting its content

Before merging the system extension with the system, we can inspect the content
of the image:

```
core@flatcar ~ $ sudo systemd-dissect --list wasmtime-24.0.0-x86-64.raw
```

## Setting up the system extension

Now we can move the image into `/var/lib/extensions` so that it will be taken
into account by `systemd-sysext`:

```
core@flatcar ~ $ sudo install -d -m 0755 -o 0 -g 0 -Z /var/lib/extensions
core@flatcar ~ $ sudo mv wasmtime-24.0.0-x86-64.raw /etc/extensions/wasmtime.raw
```

:warning: The name of the image must match the name the extension name (i.e the
suffix here: `/usr/lib/extension-release.d/extension-release.wasmtime`)

## Merging the system extension

It is now possible to merge the extensions:

```
core@flatcar ~ $ sudo systemd-sysext merge
core@flatcar ~ $ systemd-sysext status
```

## Testing out wasmtime

Let's make sure that `wasmtime` is now available:

```
core@flatcar ~ $ wasmtime --version
```

Then let's get an example WASI application and run it with `wasmtime`:

```
core@flatcar ~ $ curl -O --location https://github.com/tormath1/sysext-tutorial/raw/refs/heads/main/hands-on-1/wasi_hello_world.wasm
core@flatcar ~ $ mkdir helloworld
core@flatcar ~ $ wasmtime run --dir=$PWD::/ wasi_hello_world.wasm
Hello KubeCon London 2025!
core@flatcar ~ $ cat helloworld/helloworld.txt
Hello KubeCon London 2025!
```

## Wrapping up the hands on

You can exit the Virtual Machine by shutting it down:

```
core@flatcar ~ $ sudo poweroff
```

Or by disconnecting from the console with `Ctrl + ]` and then destroying the
virtual machine:

```
labuserX@sysext-lab:~$ virsh destroy flatcar-labuserX
```

## Resources

* [systemd-sysext man page on man7.org](https://man7.org/linux/man-pages/man8/systemd-sysext.8.html)
* [systemd-sysext man page on fdo.org](https://www.freedesktop.org/software/systemd/man/latest/systemd-sysext.html)
