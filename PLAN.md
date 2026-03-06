
OS required: 4 cores 8 GB RAM 200 GB storage Linux Ubuntu 24.04
Packer: build image based on Config + Ansible
    Config: Off Swap, 
    Load kernel modules, 
    Config sysctl, 
    Install containerd, Config containerd use systemd/cgroup, 
    Install kubeadm, kubectl, kubelet
Build Nodes, use Terraform
    Master: init cluster as control plane, install CNI plugin, Firewalls
    Worker: join cluster, Firewall