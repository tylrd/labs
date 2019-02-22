#!/usr/bin/env bash

if [ ! -f "/etc/iptables/startup.done" ]; then
  ETH0ORSIMILAR=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
  VPNHOST=${address}
  VPNIPPOOL=${subnet}
  VPNDNS="8.8.8.8"

  iptables -P INPUT   ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT  ACCEPT

  iptables -F
  iptables -t nat -F
  iptables -t mangle -F

  # accept anything already accepted
  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

  # accept anything on the loopback interface
  iptables -A INPUT -i lo -j ACCEPT

  # drop invalid packets
  iptables -A INPUT -m state --state INVALID -j DROP

  # rate-limit repeated new requests from same IP to any ports
  iptables -I INPUT -i $ETH0ORSIMILAR -m state --state NEW -m recent --set
  iptables -I INPUT -i $ETH0ORSIMILAR -m state --state NEW -m recent --update --seconds 300 --hitcount 60 -j DROP

  # accept (non-standard) SSH
  iptables -A INPUT -p tcp --dport 22 -j ACCEPT

  # accept IPSec/NAT-T for VPN (ESP not needed with forceencaps, as ESP goes inside UDP)
  iptables -A INPUT -p udp --dport  500 -j ACCEPT
  iptables -A INPUT -p udp --dport 4500 -j ACCEPT

  # forward VPN traffic anywhere
  iptables -A FORWARD --match policy --pol ipsec --dir in  --proto esp -s $VPNIPPOOL -j ACCEPT
  iptables -A FORWARD --match policy --pol ipsec --dir out --proto esp -d $VPNIPPOOL -j ACCEPT

  # reduce MTU/MSS values for dumb VPN clients
  iptables -t mangle -A FORWARD --match policy --pol ipsec --dir in -s $VPNIPPOOL -o $ETH0ORSIMILAR -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360
  iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

  # masquerade VPN traffic over eth0 etc.
  iptables -t nat -A POSTROUTING -s $VPNIPPOOL -o $ETH0ORSIMILAR -m policy --pol ipsec --dir out -j ACCEPT  # exempt IPsec traffic from masquerading
  iptables -t nat -A POSTROUTING -s $VPNIPPOOL -o $ETH0ORSIMILAR -j MASQUERADE

  # fall through to drop any other input and forward traffic

  iptables -A INPUT   -j DROP
  iptables -A FORWARD -j DROP

  iptables -L

  debconf-set-selections <<< "iptables-persistent iptables-persistent/autosave_v4 boolean true"
  debconf-set-selections <<< "iptables-persistent iptables-persistent/autosave_v6 boolean true"
  dpkg-reconfigure iptables-persistent
  touch /etc/iptables/startup.done
else
  echo 'Already configured iptables. Remove /etc/iptables/startup.done to run again.'
fi
