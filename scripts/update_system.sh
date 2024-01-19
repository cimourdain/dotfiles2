#! /bin/sh

sudo reflector --protocol https --verbose --latest 25 --sort rate --save /etc/pacman.d/mirrorlist --country France,Germany,Netherlands,Switzerland,Finland 

sudo eos-rankmirrors 

yay -Sy archlinux-keyring && yay -Syu --noconfirm

journalctl --vacuum-time=4weeks

paccache -ruk0

yay -Rns $(pacman -Qdtq)