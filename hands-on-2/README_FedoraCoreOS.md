# Hands-on 2: Build a sysext for CRI-O for Fedora CoreOS

[![asciicast](https://asciinema.org/a/710127.svg)](https://asciinema.org/a/710127)

## Setting up a Fedora CoreOS virtual machine

For this hands on, we will be using a Fedora CoreOS system.

If you are attending KubeCon London, you can connect to the lab system via SSH
and then create a Fedora CoreOS virtual machine using the command `launch_fcos`:

```
ssh labuserX@WW.XX.YY.ZZ
...
labuserX@sysext-lab:~$ launch_fcos
```

The password for the `core` user is `core`.

Otherwise, you can provision a system on any platform, using the
[documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/).

## Creating a sysext

In this hands-on, let's create a simple [CRI-O](https://cri-o.io/) system
extension. CRI-O is a container runtime for Kubernetes. It can be used as a
containerd alternative.

Let's open the file `create_crio_FedoraCoreOS.sh`. As you can see, it is mostly
a succession of "mkdir", "cd", "echo".

We download and extract the Fedora RPM for CRI-O and crit-tools into a
directory and setup a few configuration files. This will be applied as an
overlayfs on the OS.

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
WARN[0000] Config "/etc/crictl.yaml" does not exist, trying next: "/usr/bin/crictl.yaml"
Version:  0.1.0
RuntimeName:  cri-o
RuntimeVersion:  1.32.2
RuntimeApiVersion:  v1

$ systemctl status crio
● crio.service - Container Runtime Interface for OCI (CRI-O)
     Loaded: loaded (/usr/lib/systemd/system/crio.service; disabled; preset: disabled)
    Drop-In: /usr/lib/systemd/system/service.d
             └─10-timeout-abort.conf, 50-keep-warm.conf
     Active: active (running) since Wed 2025-03-26 18:40:12 UTC; 11min ago
 Invocation: 3054df2e1b454200a5205ab5450cb347
       Docs: https://github.com/cri-o/cri-o
   Main PID: 3236 (crio)
      Tasks: 9
     Memory: 74.5M (peak: 74.9M)
        CPU: 485ms
     CGroup: /system.slice/crio.service
             └─3236 /usr/bin/crio

Mar 26 18:46:42 localhost.localdomain crio[3236]: time="2025-03-26T18:46:42.128673735Z" level=warning msg="CNI plugin not yet initialized. Ignoring NetworkReady status: false, message: Network plugin returns error: no CNI configuration file in /etc/cni/net.d/. Has your network provider started?, reason: NetworkPluginNotReady"
Mar 26 18:47:12 localhost.localdomain crio[3236]: time="2025-03-26T18:47:12.12958086Z" level=warning msg="CNI plugin not yet initialized. Ignoring NetworkReady status: false, message: Network plugin returns error: no CNI configuration file in /etc/cni/net.d/. Has your network provider started?, reason: NetworkPluginNotReady"
Mar 26 18:47:42 localhost.localdomain crio[3236]: time="2025-03-26T18:47:42.131053479Z" level=warning msg="CNI plugin not yet initialized. Ignoring NetworkReady status: false, message: Network plugin returns error: no CNI configuration file in /etc/cni/net.d/. Has your network provider started?, reason: NetworkPluginNotReady"
Mar 26 18:48:12 localhost.localdomain crio[3236]: time="2025-03-26T18:48:12.132510373Z" level=warning msg="CNI plugin not yet initialized. Ignoring NetworkReady status: false, message: Network plugin returns error: no CNI configuration file in /etc/cni/net.d/. Has your network provider started?, reason: NetworkPluginNotReady"
Mar 26 18:48:42 localhost.localdomain crio[3236]: time="2025-03-26T18:48:42.133747858Z" level=warning msg="CNI plugin not yet initialized. Ignoring NetworkReady status: false, message: Network plugin returns error: no CNI configuration file in /etc/cni/net.d/. Has your network provider started?, reason: NetworkPluginNotReady"
Mar 26 18:49:12 localhost.localdomain crio[3236]: time="2025-03-26T18:49:12.135358349Z" level=warning msg="CNI plugin not yet initialized. Ignoring NetworkReady status: false, message: Network plugin returns error: no CNI configuration file in /etc/cni/net.d/. Has your network provider started?, reason: NetworkPluginNotReady"
Mar 26 18:49:42 localhost.localdomain crio[3236]: time="2025-03-26T18:49:42.137552449Z" level=warning msg="CNI plugin not yet initialized. Ignoring NetworkReady status: false, message: Network plugin returns error: no CNI configuration file in /etc/cni/net.d/. Has your network provider started?, reason: NetworkPluginNotReady"
Mar 26 18:50:12 localhost.localdomain crio[3236]: time="2025-03-26T18:50:12.142069846Z" level=warning msg="CNI plugin not yet initialized. Ignoring NetworkReady status: false, message: Network plugin returns error: no CNI configuration file in /etc/cni/net.d/. Has your network provider started?, reason: NetworkPluginNotReady"
Mar 26 18:50:42 localhost.localdomain crio[3236]: time="2025-03-26T18:50:42.143358305Z" level=warning msg="CNI plugin not yet initialized. Ignoring NetworkReady status: false, message: Network plugin returns error: no CNI configuration file in /etc/cni/net.d/. Has your network provider started?, reason: NetworkPluginNotReady"
Mar 26 18:51:12 localhost.localdomain crio[3236]: time="2025-03-26T18:51:12.145588077Z" level=warning msg="CNI plugin not yet initialized. Ignoring NetworkReady status: false, message: Network plugin returns error: no CNI configuration file in /etc/cni/net.d/. Has your network provider started?, reason: NetworkPluginNotReady"
```

## Resources

* [Example sysexts for Fedora CoreOS](https://github.com/travier/fedora-sysexts)
* [Flatcar's sysext bakery](https://github.com/flatcar/sysext-bakery/tree/main/crio.sysext)
* [systemd-sysext man page on man7.org](https://man7.org/linux/man-pages/man8/systemd-sysext.8.html)
* [systemd-sysext man page on fdo.org](https://www.freedesktop.org/software/systemd/man/latest/systemd-sysext.html)
