##########################
### dnscrypt-proxy (dnscrypt2)
# install
apt install dnscrypt-proxy
yum install dnscrypt-proxy

# configure ***servers: https://download.dnscrypt.info/dnscrypt-resolvers/v3/public-resolvers.md
mcedit /etc/dnscrypt-proxy/dnscrypt-proxy.toml
server_names = ['cloudflare', 'google']
server_names = ['google', 'cloudflare']

*centos:
listen_addresses = ['127.0.0.1:53', '127.0.2.1:53']
dnscrypt_servers = true
doh_servers = true
require_dnssec = true

# change default DNS address: 127.0.2.1
mcedit /etc/systemd/system/sockets.target.wants/dnscrypt-proxy.socket


# useful commands: 
systemctl restart NetworkManager
systemctl restart dnscrypt-proxy.socket
dnscrypt-proxy -resolve google.com
*centos:
systemctl restart dnscrypt-proxy.service
mcedit /etc/systemd/system/dnscrypt-proxy.service
*After=network.target


## references:
https://www.linuxuprising.com/2018/10/install-and-enable-dnscrypt-proxy-2-in.html
https://installati.one/centos/7/dnscrypt-proxy2/
https://www.cyberciti.biz/faq/how-to-install-dnscrypt-proxy-with-adblocker-on-linux/

##########################
### openvpn 
# install:
apt install openvpn unzip
yum install openvpn unzip

# for autostart:
mcedit /etc/default/openvpn
AUTOSTART="all"

### openvpn-proton.com
# obtain proton ovpn file:
***reference: https://settled70.blogspot.com/2019/09/ubuntu-1804.html
Netherlands (for example FREE 2nd Server)

# copy file and edit configuration:
cp nl-free-10.protonvpn.net.udp.ovpn /etc/openvpn/proton-openvpn.conf
mcedit /etc/openvpn/proton-openvpn.conf
auth-user-pass /etc/openvpn/proton-credentials

route-nopull

log /var/log/openvpn/proton-openvpn.log
status /etc/openvpn/unblock/proton-openvpn-status.log
verb 3

# Запуск скрипта при установке соединения и поднятии маршрутов
script-security 2
route-up /etc/openvpn/unblock/unblock_route.sh
route-pre-down /etc/openvpn/unblock/unblock_route.sh

# systemd autostart
add unblock-proton-ovpn.service
to /etc/systemd/system/



# useful commands:
systemctl enable openvpn
systemctl restart openvpn
systemctl enable unblock-proton-ovpn
systemctl restart unblock-proton-ovpn
ifconfig tun0
curl -s ipinfo.io
ip route show table 99
ip rule list

##########################
### routing
# rt_tables
mcedit /etc/iproute2/rt_tables
99	unblock

# cron
#centos 7
mcedit /etc/crontab
0 */12 * * * root /bin/bash --login /home/maxwell/unblock/unblock_table.sh


# ip_route
ip route add table 1000 $addr via 10.64.0.1 dev nwg1
ip route add table unblock default dev tun0
ip route add default dev tun0 table unblock
ip route add table 99 default dev tun0
ip route add table 99 95.170.188.45 dev tun0
Создаем таблицу с единственным правилом:
# ip route add default via 10.1.0.1 table 120
ip route list table unblock
ip route flush table 1000
ip route show table 1000
logger "$(ip route show table 1000 | wc -l) ips added to route table 1000"

# ip_rule
ip rule add iif br0 table 1000 priority 1777
ip rule add table 99
Создаем правило, отправляющее все пакеты в нужную таблицу:
ip rule add table 1000
Создаем правило, отправляющее нужные пакеты в нужную таблицу:
# ip rule add from 192.168.1.20 table 120
ip rule list
ip rule del iif br0 table 1000 priority 1777 2>/dev/null





