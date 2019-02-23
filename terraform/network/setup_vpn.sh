#!/usr/bin/env bash

# mangle rule if forwarding all traffic
# -A FORWARD -o eth0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1025:1536 -j TCPMSS --set-mss 1024

if [ ! -f "/etc/iptables/startup.done" ]; then
  ETH0ORSIMILAR=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
  VPNHOST=${address}
  VPNIPPOOL=${subnet}
  VPNDNS="8.8.8.8"

  iptables-restore <<EOF
*mangle
:PREROUTING ACCEPT
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
:POSTROUTING ACCEPT
COMMIT
*nat
:PREROUTING ACCEPT
:INPUT ACCEPT
:OUTPUT ACCEPT
:POSTROUTING ACCEPT
-A POSTROUTING -s $VPNIPPOOL -o eth0 -m policy --dir out --pol ipsec -j ACCEPT
-A POSTROUTING -s $VPNIPPOOL -o eth0 -j MASQUERADE
COMMIT
*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
-A INPUT -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -p udp -m udp --dport 500 -j ACCEPT
-A INPUT -p udp -m udp --dport 4500 -j ACCEPT
-A INPUT -s 169.254.169.254/32 -j ACCEPT
-A INPUT -d 169.254.169.254/32 -j ACCEPT
-A FORWARD -s $VPNIPPOOL -m policy --dir in --pol ipsec --proto esp -j ACCEPT
-A FORWARD -d $VPNIPPOOL -m policy --dir out --pol ipsec --proto esp -j ACCEPT
-A INPUT   -j DROP
-A FORWARD -j DROP
COMMIT
EOF

  debconf-set-selections <<< "iptables-persistent iptables-persistent/autosave_v4 boolean true"
  debconf-set-selections <<< "iptables-persistent iptables-persistent/autosave_v6 boolean true"
  dpkg-reconfigure iptables-persistent
  touch /etc/iptables/startup.done
else
  echo 'Already configured iptables. Remove /etc/iptables/startup.done to run again.'
fi
