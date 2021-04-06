#!/bin/bash

deluser ubuntu
rm -Rf /home/ubuntu

adduser vitalitty

usermod -aG sudo vitalitty

echo "raspberry" > /etc/hostname
vi /etc/default/keyboard
XKBLAYOUT=fr"

timedatectl set-timezone Europe/Paris

git clone https://github.com/Vitalitty/Hardening_Pi_Ubuntu.git
