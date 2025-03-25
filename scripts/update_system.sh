#! /bin/sh

echo "🤝 Update (1/2): Arch mirrors"
sudo reflector --protocol https --verbose --latest 25 --sort rate --save /etc/pacman.d/mirrorlist --country France,Germany,Netherlands,Switzerland,Finland

echo "🤝 Update (2/2): EndavourOs mirrors"
sudo eos-rankmirrors

echo "🔐 Update archlinux-keyring"
yay -Sy archlinux-keyring --noconfirm

echo "🔼 Upgrade system"
yay -Syu --noconfirm

echo "🔼 Upgrade EndavourOs"
eos-update

echo "⭐ Clean (1/2): unneeded dependencies"
yay -Scc --noconfirm

echo "⭐ Clean (2/2): journal"
sudo journalctl --vacuum-time=4weeks

echo "🖥️ System info after update"
yay -Ps