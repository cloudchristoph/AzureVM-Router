#!/bin/sh
# Enable IPv4 and IPv6 forwarding / disable ICMP redirect
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv6.conf.all.accept_redirects=0
sed -i "/net.ipv4.ip_forward=1/ s/# *//" /etc/sysctl.conf
sed -i "/net.ipv6.conf.all.forwarding=1/ s/# *//" /etc/sysctl.conf
sed -i "/net.ipv4.conf.all.accept_redirects = 0/ s/# *//" /etc/sysctl.conf
sed -i "/net.ipv6.conf.all.accept_redirects = 0/ s/# *//" /etc/sysctl.conf

if [ "$(lsb_release -r -s)" = "22.04" ]; then
  echo "Ubuntu 22.04 detected - using nftables"

  echo "Installation Netfilter-Persistent & IPTables-Persistent"
  apt-get -y install netfilter-persistent iptables-persistent

  nft add rule ip nat POSTROUTING ip daddr 10.0.0.0/8 counter accept
  nft add rule ip nat POSTROUTING ip daddr 172.16.0.0/12 counter accept
  nft add rule ip nat POSTROUTING ip daddr 192.168.0.0/16 counter accept
  nft add rule ip nat POSTROUTING oifname "eth0" counter masquerade

elif [ "$(lsb_release -r -s)" = "18.04" ]; then
  echo "Ubuntu 18.04 detected - using iptables"

  echo "Installing IPTables-Persistent"
  echo iptables-persistent iptables-persistent/autosave_v4 boolean false | sudo debconf-set-selections
  echo iptables-persistent iptables-persistent/autosave_v6 boolean false | sudo debconf-set-selections
  apt-get -y install iptables-persistent

  # Enable NAT to Internet
  iptables -t nat -A POSTROUTING -d 10.0.0.0/8 -j ACCEPT
  iptables -t nat -A POSTROUTING -d 172.16.0.0/12 -j ACCEPT
  iptables -t nat -A POSTROUTING -d 192.168.0.0/16 -j ACCEPT
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

  # Save to IPTables file for persistence on reboot
  iptables-save > /etc/iptables/rules.v4

fi


