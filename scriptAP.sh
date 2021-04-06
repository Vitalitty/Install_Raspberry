#!/bin/bash

# Configuration des interfaces
INT_WIFI="wlan0" # interface du point d'accès wifi
INT_NET="eth0" # interface wlan ou eth0 ayant Internet

# IP & mask du sous-réseau créé sur l'interface wlan
SUBNET="192.168.10.0/24"
IP="192.168.10.1"
MASK="255.255.255.0"

# Definition de quelques couleurs
red='\e[0;31m'
redhl='\e[0;31;7m'
RED='\e[1;31m'
blue='\e[0;34m'
BLUE='\e[1;34m'
cyan='\e[0;36m'
CYAN='\e[1;36m'
NC='\e[0m' # No Color

#Regarde si l'execution est bien en root (i.e. sudo)
if [ $USER != "root" ]
then
    echo -e $RED"Vous devez être root pour lancer ce progamme!"$NC
    exit 1
fi

#Verifie si tous les modules sont bien installes
ifconfig=$(which ifconfig)
if [ $? != 0 ]
then
    echo -e $RED"Erreur Fatale: Un problème est survenue: Impossible de trouver la commande ifconfig!"$NC
    exit 1
fi

hostapd=$(which hostapd)
if [ $? != 0 ]
then
    echo -e $RED"Erreur Fatale: Vous devez installer hostapd!"$NC
    exit 1
fi

dnsmasq=$(which dnsmasq)
if [ $? != 0 ]
then
    echo -e $RED"Erreur Fatale: Vous devez installer dnsmasq!"$NC
    exit 1
fi

udhcpd=$(which udhcpd)
if [ $? != 0 ]
then
    echo -e $RED"Erreur Fatale: Vous devez installer udhcpd!"$NC
    exit 1
fi

echo -e $blue"Démarrage et configuration de l'interface wifi $INT_WIF..."$NC
sudo ifconfig $INT_WIFI down
sleep 4
sudo ifconfig $INT_WIFI $IP netmask $MASK up
sleep 4

echo -e $blue"Démarrage daemon hostapd..."$NC
# start hostapd server (see /etc/hostapd/hostapd.conf)
# sudo hostapd /etc/hostapd/hostapd.conf &
sudo systemctl start hostapd
sleep 1

echo -e $blue"Démarrage daemon dnsmasq... "$NC
# start dnsmasq server (see /etc/dnsmasq.conf) -7 /etc/dnsmasq.d
#sudo dnsmasq -x /var/run/dnsmasq.pid -C /etc/dnsmasq.conf
sudo systemctl start dnsmasq
sleep 1

echo -e $blue"Démarrage daemon dhcpd... "$NC
# start or resart dhcpd server (see /etc/dhcpd/dhcpd.conf)
#sudo touch /var/lib/dhcp/dhcp.leases
#sudo mkdir /var/run/dhcp-server
#sudo chown dhcp:dhcp /var/run/dhcp-server
#sudo dhcp -d -f -pf /var/run/dhcp-server/dhcp.pid -cf /etc/dhcp/dhcp.conf $INT_WIFI &
systemctl restart udhcpd
sleep 2

# Turn on IP forwarding (faire suivre les paquets d'une interface à l'autre)
echo 1 > /proc/sys/net/ipv4/ip_forward

echo -e $blue"Activation iptables NAT MASQUERADE interface $NC$red$INT_NET$NC"
# load masquerade module
sudo modprobe ipt_MASQUERADE
sudo iptables -A POSTROUTING -t nat -o $INT_NET -j MASQUERADE

echo -e $blue"Activation iptables FORWARD & INPUT entre interface $NC$red$INT_WIFI$NC$blue & sous-réseau $NC$red$SUBNET$NC"
sudo iptables -A FORWARD --match state --state RELATED,ESTABLISHED --jump ACCEPT
sudo iptables -A FORWARD -i $INT_WIFI --destination $SUBNET --match state --state NEW --jump ACCEPT
sudo iptables -A INPUT -s $SUBNET --jump ACCEPT
