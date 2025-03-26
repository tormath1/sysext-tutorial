# Hands-on 3: Build a simple Kubernetes Cluster on Flatcar and FCOS

For this hands on, we will deploy a simple kubernetes cluster with 1 node and 1 control plane:
* Flatcar system as control-plane
* FCOS as a worker node.

If you are attending KubeCon London, you can connect to the lab system via SSH
and then create a Flatcar virtual machine using the command `launch_flatcar`:

```
$ ssh labuserX@WW.XX.YY.ZZ
...
```

## Deploying control-plane

Kubernetes sysexts are already available, you just need to provision a Flatcar instance with the following configuration:
```yaml
---
version: 1.1.0
variant: flatcar
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
        ExecStartPre=/usr/bin/kubeadm init --node-name flatcar-cp --ignore-preflight-errors=NumCPU,Mem
        ExecStartPre=/usr/bin/mkdir /home/core/.kube
        ExecStartPre=/usr/bin/cp /etc/kubernetes/admin.conf /home/core/.kube/config
        ExecStart=/usr/bin/chown -R core:core /home/core/.kube
        [Install]
        WantedBy=multi-user.target
```

Copy the configuration above in a file called: "control-plane.yaml" and generate the Ignition configuration.
```bash
butane < control-plane.yaml > control-plane.json
```

You can start the Flatcar control-plane with:
```
launch_flatcar -i ./control-plane.json
```

After a few seconds, the instance should be booted and the control-plane available (but not ready yet):
```
core@localhost ~ $ kubectl get nodes
NAME        STATUS     ROLES           AGE   VERSION
flatcar-cp  NotReady   control-plane   22s   v1.32.2
```


## Deploying a worker node

We will deploy a worker node on FCOS using this configuration:
```yaml
variant: fcos
version: 1.5.0
passwd:
  users:
    - name: core
      password_hash: $y$j9T$hCQJnZ9k0Al6j6rd9H59X1$n2b6ycQDiVL5POfwtfLBue9shrrVN3zzzMZ37Kia090
      ssh_authorized_keys:
        - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAT23SVMyX5QOh3RzUpiVLO5f7MzhenlN0zjtWsncdqE labuser@fcos-sysext-lab
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
          %%HOSTNAME%%
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
    # Enable CRI-O
    - name: crio.service
      enabled: true
    # Enable kubelet
    - name: kubelet.service
      enabled: true
    # Disable auto-updates via Zincati for now (see fleetlock)
    - name: zincati.service
      enabled: false
      mask: true
```

Copy the configuration above in a file called: "worker.yaml" and generate the Ignition configuration.
```bash
butane < worker.yaml > worker.json
```

You can start the FCOS worker with:
```
launch_fcos -i ./worker.json
```

From the Flatcar instance, you can print the join command:
```
kubeadm token create --print-join-command
```
and from the worker node, you can paste the result of the command above:
```
kubeadm join ... --node-name fcos-worker-01
```

Congratulations, you have deployed a Kubernetes cluster on Flatcar / FCOS using Systemd-sysext!

```
core@localhost ~ $ kubectl get nodes -o wide
NAME              STATUS     ROLES           AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE                                             KERNEL-VERSION           CONTAINER-RUNTIME
fcos-worker-01    NotReady   <none>          4s    v1.32.3   192.168.124.103   <none>        Fedora CoreOS 41.20250302.3.2                        6.13.5-200.fc41.x86_64   cri-o://1.32.2
flatcar-cp        NotReady   control-plane   23m   v1.32.2   192.168.124.254   <none>        Flatcar Container Linux by Kinvolk 4152.2.2 (Oklo)   6.6.83-flatcar           containerd://1.7.23

```

If you want your nodes to be ready, you can deploy a simple CNI like calico:
```
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/calico.yaml
```

## Resources

* https://github.com/travier/fedora-coreos-kubernetes
* https://www.flatcar.org/docs/latest/container-runtimes/getting-started-with-kubernetes/
* https://www.flatcar.org/docs/latest/container-runtimes/high-availability-kubernetes/
