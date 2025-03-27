# Hands-on 3: Setup a small Kubernetes Cluster with Flatcar and Fedora CoreOS nodes, using sysexts

For this hands on, we will deploy a Kubernetes cluster with 1 node and 1
control plane:

* one Flatcar Container Linux system as control-plane
* one Fedora CoreOS system as worker node

If you are attending KubeCon London, you can connect to the lab system via SSH:

```
ssh labuserX@WW.XX.YY.ZZ
```

## Deploying the control-plane node

Kubernetes sysexts are already available for Flatcar Container Linux, so you
only need to provision a Flatcar instance with the following configuration:

```yaml
variant: flatcar
version: 1.1.0
passwd:
  users:
    - name: core
      password_hash: $y$j9T$hCQJnZ9k0Al6j6rd9H59X1$n2b6ycQDiVL5POfwtfLBue9shrrVN3zzzMZ37Kia090
      ssh_authorized_keys:
        - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAT23SVMyX5QOh3RzUpiVLO5f7MzhenlN0zjtWsncdqE labuser@sysext-lab
storage:
  links:
    - target: /opt/extensions/kubernetes/kubernetes-v1.32.2-x86-64.raw
      path: /etc/extensions/kubernetes.raw
      hard: false
  files:
    - path: /etc/sysupdate.kubernetes.d/kubernetes-v1.32.conf
      contents:
        source: https://github.com/flatcar/sysext-bakery/releases/download/kubernetes-v1.32.2/kubernetes-v1.32.conf
    - path: /etc/sysupdate.d/noop.conf
      contents:
        source: https://github.com/flatcar/sysext-bakery/releases/download/latest/noop.conf
    - path: /opt/extensions/kubernetes/kubernetes-v1.32.2-x86-64.raw
      contents:
        source: https://github.com/flatcar/sysext-bakery/releases/download/kubernetes-v1.32.2/kubernetes-v1.32.2-x86-64.raw
    - path: /etc/hostname
      contents:
        inline: |
          flatcar-cp
systemd:
  units:
    - name: systemd-sysupdate.timer
      enabled: true
    - name: systemd-sysupdate.service
      dropins:
        - name: kubernetes.conf
          contents: |
            [Service]
            ExecStartPre=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/kubernetes.raw > /tmp/kubernetes"
            ExecStartPre=/usr/lib/systemd/systemd-sysupdate -C kubernetes update
            ExecStartPost=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/kubernetes.raw > /tmp/kubernetes-new"
            ExecStartPost=/usr/bin/sh -c "if ! cmp --silent /tmp/kubernetes /tmp/kubernetes-new; then touch /run/reboot-required; fi"
    - name: locksmithd.service
      # NOTE: To coordinate the node reboot in this context, we recommend to use Kured.
      mask: true
    - name: kubeadm.service
      enabled: true
      contents: |
        [Unit]
        Description=Kubeadm service
        Requires=containerd.service
        After=containerd.service
        ConditionPathExists=!/etc/kubernetes/kubelet.conf
        [Service]
        ExecStartPre=/usr/bin/kubeadm init --ignore-preflight-errors=NumCPU,Mem
        ExecStartPre=/usr/bin/mkdir /home/core/.kube
        ExecStartPre=/usr/bin/cp /etc/kubernetes/admin.conf /home/core/.kube/config
        ExecStart=/usr/bin/chown -R core:core /home/core/.kube
        [Install]
        WantedBy=multi-user.target
```

Copy the configuration above in a file called `control-plane.yaml` and
generate the Ignition configuration:

```bash
labuserX@sysext-lab:~$ butane < control-plane.yaml > control-plane.json
```

You can start the Flatcar control-plane virtual machine on the lab system via:

```
labuserX@sysext-lab:~$ launch_flatcar -i ./control-plane.json
```

After a few seconds, the instance should be booted and the control-plane
available (but not ready yet):

```
core@flatcar ~ $ kubectl get nodes
NAME        STATUS     ROLES           AGE   VERSION
flatcar-cp  NotReady   control-plane   22s   v1.32.2
```

You can exit the console of the Flatcar Container Linux virtual machine
(leaving it running) with `Ctrl + ]`. You can also use another ssh session to
do the next steps of the hands on to see both consoles in parallel.

## Deploying a worker node

We will deploy a worker node on Fedora CoreOS using this configuration:

```yaml
variant: fcos
version: 1.5.0
passwd:
  users:
    - name: core
      password_hash: $y$j9T$hCQJnZ9k0Al6j6rd9H59X1$n2b6ycQDiVL5POfwtfLBue9shrrVN3zzzMZ37Kia090
      ssh_authorized_keys:
        - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAT23SVMyX5QOh3RzUpiVLO5f7MzhenlN0zjtWsncdqE labuser@sysext-lab
storage:
  directories:
    - path: /etc/sysupdate.d
    - path: /var/lib/extensions
    - path: /var/lib/extensions.d
  files:
    - path: "/var/lib/extensions.d/kubernetes-v1.32.raw"
      contents:
        source: "https://github.com/travier/fedora-sysexts/releases/download/fedora-coreos-stable/kubernetes-cri-o-1.32-41.20250302.3.2-x86-64.raw"
    - path: "/etc/sysctl.d/kubernetes.conf"
      contents:
        inline: |
          net.ipv4.ip_forward = 1
    - path: "/etc/modules-load.d/kubernetes.conf"
      contents:
        inline: |
          br_netfilter
    - path: "/etc/hostname"
      contents:
        inline: |
          fedora-coreos-worker
    - path: "/etc/sysconfig/crio"
      contents:
        inline: |
          # Setup default CRI-O config from the sysext
          CRIO_CONFIG_OPTIONS="--config /usr/etc/crio/crio.conf"
  links:
    - path: "/var/lib/extensions/kubernetes-cri-o-1.32.raw"
      target: "../extensions.d/kubernetes-v1.32.raw"
      hard: false
systemd:
  units:
    # Setup sysexts
    - name: systemd-sysext.service
      enabled: true
    # We will use CRI-O
    - name: docker.socket
      enabled: false
      mask: true
    # Disable auto-updates via Zincati for now (see fleetlock)
    - name: zincati.service
      enabled: false
      mask: true
```

Copy the configuration above in a file called `worker.yaml` and generate the
Ignition configuration:

```bash
labuserX@sysext-lab:~$ butane < worker.yaml > worker.json
```

You can start the Fedora CoreOS worker virtual machine on the lab system via:

```
labuserX@sysext-lab:~$ launch_fcos -i ./worker.json
```

You can exit the console of the Fedora CoreOS virtual machine (leaving it
running) with `Ctrl + ]`. You can also use another ssh session to see both
console in parallel.

Connect back to the console of the Flatcar virtual machine with:

```
labuserX@sysext-lab:~$ virsh console flatcar-labuserX
```

From the Flatcar instance, you can print the join command:

```
core@flatcar ~ $ kubeadm token create --print-join-command
```

And on the Fedora CoreOS worker node, you can paste the result of the command above:

```
[core@fedora-coreos ~]$ sudo kubeadm join ...
```

Congratulations, you have deployed a Kubernetes cluster on Flatcar and Fedora
CoreOS using systemd system extensions!

On the Flatcar instannce:

```
core@flatcar ~ $ kubectl get nodes -o wide
NAME                  STATUS     ROLES           AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE                                             KERNEL-VERSION           CONTAINER-RUNTIME
fedora-coreos-worker  NotReady   <none>          4s    v1.32.3   192.168.124.103   <none>        Fedora CoreOS 41.20250302.3.2                        6.13.5-200.fc41.x86_64   cri-o://1.32.2
flatcar-cp            NotReady   control-plane   23m   v1.32.2   192.168.124.254   <none>        Flatcar Container Linux by Kinvolk 4152.2.2 (Oklo)   6.6.83-flatcar           containerd://1.7.23
```

If you want your nodes to be ready, you can deploy a simple CNI like calico:

```
core@flatcar ~ $ kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/calico.yaml
```

Then tag the worker node:

```
core@flatcar ~ $ kubectl label node fedora-coreos-worker node-role.kubernetes.io/worker=worker
```

And then deploy an example application:

```
core@flatcar ~ $ kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
core@flatcar ~ $ kubectl get pods -o wide
```

## Wrapping up the hands on

You can exit any Virtual Machine by shutting it down:

```
$ sudo poweroff
```

Or by disconnecting from the console with `Ctrl + ]` and then destroying the
virtual machine:

```
labuserX@sysext-lab:~$ virsh destroy fcos-labuserX
labuserX@sysext-lab:~$ virsh destroy flatcar-labuserX
```

## Resources

* [Getting started with Kubernetes, from the Flatcar Container Linux documentation](https://www.flatcar.org/docs/latest/container-runtimes/getting-started-with-kubernetes/)
* [High Availability Kubernetes, from the Flatcar Container Linux documentation](https://www.flatcar.org/docs/latest/container-runtimes/high-availability-kubernetes/)
* [Deploy Kubernetes on Fedora CoreOS using sysexts](https://github.com/travier/fedora-coreos-kubernetes)
