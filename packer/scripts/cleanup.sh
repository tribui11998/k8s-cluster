#!/bin/bash
set -e

echo ">>> Cleaning up image..."

# Clean apt
sudo apt-get clean
sudo apt-get autoremove -y
sudo rm -rf /var/lib/apt/lists/*

# Clean temp
sudo rm -rf /tmp/* /var/tmp/*

# Clean logs
sudo find /var/log -type f -exec truncate -s 0 {} \;
sudo rm -rf /var/log/journal/*

# Clean SSH host keys (regenerate on first boot)
sudo rm -f /etc/ssh/ssh_host_*

# Clean machine-id (regenerate on first boot)
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id

# Clean cloud-init
sudo cloud-init clean --logs --seed

# Clean history
rm -f ~/.bash_history
sudo rm -f /root/.bash_history
history -c || true

sync
echo ">>> Cleanup complete."