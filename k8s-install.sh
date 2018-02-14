#!/bin/bash

# Docker
systemctl enable docker && systemctl start docker

# CNI
CNI_VERSION="v0.6.0"
mkdir -p /opt/cni/bin
echo 'export PATH=$PATH:/opt/cni/bin' > /etc/profile.d/path-opt-cni-bin.sh
source /etc/profile.d/path-opt-cni-bin.sh
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz

# Install Kubernetes
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
mkdir -p /opt/bin
echo 'export PATH=$PATH:/opt/bin' > /etc/profile.d/path-opt-bin.sh
source /etc/profile.d/path-opt-bin.sh
cd /opt/bin
curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}
chmod +x {kubeadm,kubelet,kubectl}

# Kubelet Service
curl -sSL "https://raw.githubusercontent.com/kubernetes/kubernetes/${RELEASE}/build/debs/kubelet.service" | sed "s:/usr/bin:/opt/bin:g" > /etc/systemd/system/kubelet.service
mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/kubernetes/${RELEASE}/build/debs/10-kubeadm.conf" | sed "s:/usr/bin:/opt/bin:g" > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Networking
sysctl net.bridge.bridge-nf-call-iptables=1
ip=$(ip -f inet -o addr show eth1|cut -d\  -f 7 | cut -d/ -f 1)
hostname=`hostname`
echo "$ip $hostname" >> /etc/hosts
