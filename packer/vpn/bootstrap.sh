#!/bin/bash

set -ex

apt-get update
apt-get install -y strongswan iptables-persistent

cat <<EOF > /etc/ipsec.secrets
$IPADDRESS : RSA "vpn-key.pem"
EOF

cat <<EOF > /etc/ipsec.conf
config setup
  charondebug="ike 1, knl 1, cfg 2"
  uniqueids=no

conn ikev2-vpn
  auto=add
  compress=no
  type=tunnel
  keyexchange=ikev2
  fragmentation=yes
  forceencaps=yes
  ike=aes256-sha1-modp1024,3des-sha1-modp1024!
  esp=aes256-sha1,3des-sha1!
  dpdaction=clear
  dpddelay=60s
  rekey=no
  left=%any
  leftid=$IPADDRESS
  leftcert=vpn-cert.pem
  leftsendcert=always
  leftsubnet=0.0.0.0/0
  right=%any
  rightid=%any
  rightsourceip=$SUBNET
  rightdns=$DNS
EOF

mv /tmp/vpn-cert.pem /etc/ipsec.d/certs/
mv /tmp/vpn-key.pem /etc/ipsec.d/private/
mv /tmp/ca.pem /etc/ipsec.d/cacerts/

chown root: /etc/ipsec.d/certs/vpn-cert.pem
chown root: /etc/ipsec.d/private/vpn-key.pem
chown root: /etc/ipsec.d/cacerts/ca.pem
chmod 600 /etc/ipsec.d/private/vpn-key.pem

echo '
# vpn metadata startup
net.ipv4.ip_forward = 1
net.ipv4.ip_no_pmtu_disc = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
' >> /etc/sysctl.conf

sysctl -p
