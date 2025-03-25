# Hands-on 2: Build a simple sysext

In this hands-on, let's create a simple [CRI-O](https://cri-o.io/) image. CRI-O is a container runtime for Kubernetes, it can be used as a Containerd alternative.

Let's open the file `create_crio.sh`. As you can see, it is only a succession of "mkdir", "cd", "echo". 

We basically create a directory `usr/` and we put everything we need to run CRI-O inside this directory: this will be applied as overlayfs on the OS.

## Build the sysext

From your FCOS instance:
```
git clone https://github.com/tormath1/sysext-tutorial
cd sysext-tutorial/hands-on-2
```

Build the sysext:
```
bash create_crio.sh
```

Upload the sysext to the Flatcar instance and merge it to the system:
```
scp crio.raw flatcar:/home/core/crio.raw
ssh flatcar
sudo mv crio.raw /etc/extensions
# refresh and not 'merge' because some extensions are already loaded by default
sudo systemd-sysext refresh
```

You have extended your Flatcar instance with a new container runtime:
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
core@localhost ~ $ systemctl status crio
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

Resources:
* https://github.com/flatcar/sysext-bakery/blob/main/create_crio_sysext.sh
* https://man7.org/linux/man-pages/man8/systemd-sysext.8.html
