#!/bin/bash
set -euo pipefail

echo "========================================"
echo "K8s Node Setup - Started at $(date)"
echo "K8s Version: ${K8S_VERSION:-1.31}"
echo "========================================"

# ============================================================
# 1. DISABLE SWAP
# ============================================================
echo ">>> Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# ============================================================
# 2. KERNEL MODULES
# ============================================================
echo ">>> Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# ============================================================
# 3. SYSCTL
# ============================================================
echo ">>> Configuring sysctl..."
cat <<EOF | sudo tee /etc/sysctl.d/99-k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
vm.swappiness                       = 0
fs.inotify.max_user_watches         = 524288
fs.inotify.max_user_instances       = 8192
EOF

sudo sysctl --system

# ============================================================
# 4. INSTALL PACKAGES
# ============================================================
echo ">>> Installing base packages..."
sudo apt-get update -y
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  jq \
  socat \
  conntrack \
  nfs-common \
  chrony \
  auditd \
  fail2ban \
  unattended-upgrades \
  logrotate

# ============================================================
# 5. INSTALL CONTAINERD
# ============================================================
echo ">>> Installing containerd..."
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod 644 /etc/apt/keyrings/docker.gpg

CODENAME=$(lsb_release -cs)
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get update -y
sudo apt-get install -y containerd.io

# ============================================================
# 6. CONFIGURE CONTAINERD
# ============================================================
echo ">>> Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# Enable CRI plugin
sudo sed -i 's/disabled_plugins = \["cri"\]/disabled_plugins = []/' /etc/containerd/config.toml

# Use systemd cgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Set pause image
sudo sed -i 's|sandbox_image = ".*"|sandbox_image = "registry.k8s.io/pause:3.10"|' /etc/containerd/config.toml

# Restart & enable
sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl enable containerd

# Wait for containerd
echo ">>> Waiting for containerd..."
for i in $(seq 1 30); do
  if sudo ctr --connect-timeout 5s version &>/dev/null; then
    echo "containerd is ready."
    break
  fi
  echo "Attempt $i/30..."
  sleep 2
done

# ============================================================
# 7. INSTALL KUBEADM, KUBELET, KUBECTL
# ============================================================
echo ">>> Installing Kubernetes ${K8S_VERSION}..."
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key" \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet
sudo systemctl enable kubelet

# ============================================================
# 8. CONFIGURE CRICTL
# ============================================================
echo ">>> Configuring crictl..."
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# Verify crictl
echo ">>> Verifying crictl..."
for i in $(seq 1 10); do
  if sudo crictl info &>/dev/null; then
    echo "crictl is working."
    break
  fi
  echo "Attempt $i/10..."
  sleep 3
done

# ============================================================
# 9. PRE-PULL IMAGES
# ============================================================
echo ">>> Pre-pulling K8s images..."
sudo kubeadm config images pull

# ============================================================
# 10. SSH HARDENING
# ============================================================
echo ">>> Hardening SSH..."
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config

# ============================================================
# 11. FAIL2BAN
# ============================================================
echo ">>> Configuring fail2ban..."
cat <<EOF | sudo tee /etc/fail2ban/jail.d/sshd.conf
[sshd]
enabled = true
port = ssh
maxretry = 5
bantime = 3600
findtime = 600
EOF

sudo systemctl enable fail2ban

# ============================================================
# 12. KUBECTL ALIASES
# ============================================================
echo ">>> Setting up kubectl aliases..."
cat <<'EOF' | sudo tee /etc/profile.d/kubectl.sh
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kga='kubectl get all -A'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kaf='kubectl apply -f'
source <(kubectl completion bash)
complete -o default -F __start_kubectl k
EOF

# ============================================================
# 13. CREATE K8S DIRECTORIES
# ============================================================
echo ">>> Creating K8s directories..."
sudo mkdir -p /etc/kubernetes/manifests
sudo mkdir -p /etc/kubernetes/pki
sudo mkdir -p /var/log/kubernetes
sudo chmod 700 /etc/kubernetes /etc/kubernetes/pki

echo "========================================"
echo "K8s Node Setup Complete - $(date)"
echo "========================================"