# Hands-on 2: Build a simple sysext on Fedora CoreOS

## Setting up a Fedora CoreOS virtual machine

For this hands on, we will be using a Fedora CoreOS system.

If you are attending KubeCon London, you can connect to the lab system via SSH
and then create a Fedora CoreOS virtual machine using the command `launch_fcos`:

```
ssh labuserX@WW.XX.YY.ZZ
...
labuserX@sysext-lab:~$ launch_fcos
```

Otherwise, you can provision a system on any platform, using the
[documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/).

## Creating a sysext

In this hands-on, let's create a simple [CRI-O](https://cri-o.io/) image. CRI-O
is a container runtime for Kubernetes. It can be used as a Containerd
alternative.

Let's open the file `create_crio.sh`. As you can see, it is mostly a succession
of "mkdir", "cd", "echo".

We basically create a directory `usr/` and we put everything we need to run
CRI-O inside this directory: this will be applied as an overlayfs on the OS.

## Building the sysext

From the main `sysext-lab` system, clone the Git repo with the script:

```
git clone https://github.com/tormath1/sysext-tutorial
cd sysext-tutorial/hands-on-2
```

Build the sysext:

```
./create_crio_FedoraCoreOS.sh
```

## Get the system extension to the Virtual Machine

Upload the sysext to the Fedora CoreOS instance and merge it to the system:

```
scp crio.raw core@WW.XX.YY.ZZ:crio.raw
ssh core@WW.XX.YY.ZZ
sudo install -d -m 0755 -o 0 -g 0 -Z /var/lib/extensions
sudo mv crio.raw /var/lib/extensions
sudo systemctl restart systemd-sysext.service
```

:warning: We can not use `sudo systemd-sysext merge` directly here as there is
an incompatibility between systemd and SELinux that is fixed in systemd v257
only.

## Test CRI-O

You have extended your Fedora CoreOS instance with a new container runtime:

```
$ sudo crictl --runtime-endpoint unix:///run/crio/crio.sock version
Version:  0.1.0
RuntimeName:  cri-o
RuntimeVersion:  1.32.2
RuntimeApiVersion:  v1

$ sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock version
Version:  0.1.0
RuntimeName:  containerd
RuntimeVersion:  v1.7.23
RuntimeApiVersion:  v1

$ systemctl status crio
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

## Resources

* [Example sysexts for Fedora CoreOS](https://github.com/travier/fedora-sysexts)
* [Flatcar's sysext bakery](https://github.com/flatcar/sysext-bakery/blob/main/create_crio_sysext.sh)
* [systemd-sysext man page on man7.org](https://man7.org/linux/man-pages/man8/systemd-sysext.8.html)
* [systemd-sysext man page on fdo.org](https://www.freedesktop.org/software/systemd/man/latest/systemd-sysext.html)
