#!/bin/bash

set -ex

apt-get update
apt-get install -y strongswan iptables-persistent

cat <<EOF > /etc/ipsec.secrets
$HOSTNAME : RSA "key.pem"
EOF

cat <<EOF > /etc/ipsec.conf
config setup
  charondebug="ike 1, knl 1, cfg 0"
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
  leftid=@$HOSTNAME
  leftcert=cert.pem
  leftsendcert=always
  leftsubnet=$SUBNET
  right=%any
  rightid=%any
  rightsourceip=$SUBNET
  rightdns=169.254.169.254
EOF

mv /tmp/cert.pem /etc/ipsec.d/certs/
mv /tmp/key.pem /etc/ipsec.d/private/
mv /tmp/chain.pem /etc/ipsec.d/cacerts/

chown root: /etc/ipsec.d/certs/cert.pem
chown root: /etc/ipsec.d/private/key.pem
chown root: /etc/ipsec.d/cacerts/chain.pem
chmod 600 /etc/ipsec.d/private/key.pem

echo '
# vpn metadata startup
net.ipv4.ip_forward = 1
net.ipv4.ip_no_pmtu_disc = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.forwarding=1
' >> /etc/sysctl.conf

sysctl -p
