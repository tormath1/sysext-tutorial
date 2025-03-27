# Hands-on 2: Build a sysext for CRI-O for Flatcar Container Linux

[![asciicast](https://asciinema.org/a/707977.svg)](https://asciinema.org/a/707977)

## Connecting to the lab system

If you are attending KubeCon London, you can connect to the lab system via SSH:

```
ssh labuserX@WW.XX.YY.ZZ
```

## Building a sysext

**Make sure that you are only connected to the lab system before moving
further. You don't need to connect to the Flacar Container Linux virtual
machine yet.**

In this hands-on, we will build a simple [CRI-O](https://cri-o.io/) system
extension. CRI-O is a container runtime for Kubernetes. It can be used as a
containerd alternative.

First, let's get the script that we will use to build the system extension:

```
labuserX@sysext-lab:~$ git clone https://github.com/tormath1/sysext-tutorial
labuserX@sysext-lab:~$ cd sysext-tutorial/hands-on-2
```

Let's open the file `create_crio.sh`. As you can see, it is mostly a succession
of "mkdir", "cd", "echo".

We basically create a directory `usr/` and we put everything we need to run
CRI-O inside this directory. This will be applied as an overlayfs on the OS.

Let's now build this system extension:

```
labuserX@sysext-lab:~$ ./create_crio.sh
```

## Setting up a Flatcar Container Linux virtual machine

We will now setup a Flatcar Container Linux virtual machine.

If you are attending KubeCon London, you can create a Flatcar virtual machine
using the command `launch_flatcar`:

```
labuserX@sysext-lab:~$ launch_flatcar
```

The password for the `core` user is `core`.

Otherwise, you can provision a system on any platform, using the
[documentation](https://www.flatcar.org/docs/latest/installing/).

## Get the system extension to the Virtual Machine

Get the IP address of the Flatcar Container Linux virtual machine:

```
core@flatcar ~ $ ip addr
...
```

Exit the Flatcar Container Linux virtual machine console with `Ctrl + ]`.

Upload the sysext to the Flatcar instance:

```
labuserX@sysext-lab:~$ scp crio.raw core@WW.XX.YY.ZZ:crio.raw
```

Connect back to the Flatcar Container Linux virtual machine console:

```
labuserX@sysext-lab:~$ virsh console flatcar-labuserX
```

And then setup the systemd system extension and merge it to the system:

```
core@flatcar ~ $ sudo mv crio.raw /etc/extensions
# Use 'refresh' and not 'merge' because some extensions are already loaded by default
core@flatcar ~ $ sudo systemd-sysext refresh
```

## Test CRI-O

You have extended your Flatcar instance with a new container runtime:

```
core@flatcar ~ $ sudo crictl --runtime-endpoint unix:///run/crio/crio.sock version
Version:  0.1.0
RuntimeName:  cri-o
RuntimeVersion:  1.32.2
RuntimeApiVersion:  v1

core@flatcar ~ $ sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock version
Version:  0.1.0
RuntimeName:  containerd
RuntimeVersion:  v1.7.23
RuntimeApiVersion:  v1

core@flatcar ~ $ systemctl status crio
● crio.service - Container Runtime Interface for OCI (CRI-O)
     Loaded: loaded (/usr/lib/systemd/system/crio.service; disabled; preset: disabled)
    Drop-In: /usr/lib/systemd/system/crio.service.d
             └─10-crio.conf
     Active: active (running) since Thu 2025-03-13 14:26:57 UTC; 2min 27s ago
       Docs: https://github.com/cri-o/cri-o
    Process: 1789 ExecStartPre=/usr/bin/mkdir -p /opt/cni/bin /etc/crio/crio.conf.d/ /etc/cni/net.d/ /var/log/crio (code=exited, status=0/SUCCESS)
    Process: 1791 ExecStartPre=/usr/bin/rsync -ur /usr/share/crio/etc/ /etc/ (code=exited, status=0/SUCCESS)
   Main PID: 1794 (crio)
      Tasks: 9
     Memory: 79.1M (peak: 79.6M)
        CPU: 632ms
     CGroup: /system.slice/crio.service
             └─1794 /usr/bin/crio --config-dir /etc/crio/crio.conf.d/

Mar 13 14:26:57 localhost crio[1794]: time="2025-03-13T14:26:57.626739859Z" level=info msg="Registered SIGHUP reload watcher"
Mar 13 14:26:57 localhost crio[1794]: time="2025-03-13T14:26:57.626811023Z" level=info msg="Starting seccomp notifier watcher"
Mar 13 14:26:57 localhost crio[1794]: time="2025-03-13T14:26:57.626950036Z" level=info msg="Create NRI interface"
Mar 13 14:26:57 localhost crio[1794]: time="2025-03-13T14:26:57.627192074Z" level=info msg="runtime interface created"
Mar 13 14:26:57 localhost crio[1794]: time="2025-03-13T14:26:57.627279821Z" level=info msg="Registered domain \"k8s.io\" with NRI"
Mar 13 14:26:57 localhost crio[1794]: time="2025-03-13T14:26:57.62730498Z" level=info msg="runtime interface starting up..."
Mar 13 14:26:57 localhost crio[1794]: time="2025-03-13T14:26:57.627688995Z" level=info msg="starting plugins..."
Mar 13 14:26:57 localhost crio[1794]: time="2025-03-13T14:26:57.627743385Z" level=info msg="Synchronizing NRI (plugin) with current runtime state"
Mar 13 14:26:57 localhost crio[1794]: time="2025-03-13T14:26:57.627951853Z" level=info msg="No systemd watchdog enabled"
Mar 13 14:26:57 localhost systemd[1]: Started crio.service - Container Runtime Interface for OCI (CRI-O).
```

## Wrapping up the hands on

If you are attending KubeCon London, you can exit the Virtual Machine
by shutting it down:

```
core@flatcar ~ $ sudo poweroff
```

Or by disconnecting from the console with `Ctrl + ]` and then destroying the
virtual machine:

```
labuserX@sysext-lab:~$ virsh destroy flatcar-labuserX
```

## Resources

* [Flatcar's sysext bakery](https://github.com/flatcar/sysext-bakery/tree/main/crio.sysext)
* [systemd-sysext man page on man7.org](https://man7.org/linux/man-pages/man8/systemd-sysext.8.html)
* [systemd-sysext man page on fdo.org](https://www.freedesktop.org/software/systemd/man/latest/systemd-sysext.html)
* [Example sysexts for Fedora CoreOS](https://github.com/travier/fedora-sysexts)
