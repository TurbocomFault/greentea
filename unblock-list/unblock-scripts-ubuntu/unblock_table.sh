#!/bin/bash

source /etc/openvpn/unblock/unblock-vars


wget -q -O $UNBLOCK_PATH/unblock.txt $UNBLOCK_URL
ip route flush table $TABLE_NUM

cut_local() {
  grep -vE 'localhost|^0\.|^127\.|^10\.|^172\.16\.|^192\.168\.|^::|^fc..:|^fd..:|^fe..:'
}

#until ADDRS=$(dig +short google.com @localhost -p 9153) && [ -n "$ADDRS" ] > /dev/null 2>&1; do sleep 5; done
until ADDRS=$(nslookup google.com $LOCAL_DNS | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -v $LOCAL_DNS) && [ -n "$ADDRS" ] > /dev/null 2>&1; do sleep 5; done

#
while read line || [ -n "$line" ]; do
#
  [ -z "$line" ] && continue
  [ "${line:0:1}" = "#" ] && continue
#
  dns_addr=$(echo $line)
  site_addrs=$(nslookup $dns_addr $LOCAL_DNS | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -v $LOCAL_DNS)
  for ip_addr in $site_addrs; do
    if [ ! -z "$ip_addr" ]; then
      ip route add table $TABLE_NUM $ip_addr dev $OVPN_DEV 2>/dev/null
      continue
    fi
  done
#
  addr=$(echo $line | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
  if [ ! -z "$addr" ]; then
    ip route add table $TABLE_NUM $addr dev $OVPN_DEV 2>/dev/null
    continue
  fi
#
  cidr=$(echo $line | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}')
  if [ ! -z "$cidr" ]; then
    ip route add table $TABLE_NUM $cidr dev $OVPN_DEV 2>/dev/null
    continue
  fi
#
  range=$(echo $line | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
  if [ ! -z "$range" ]; then
    ip route add table $TABLE_NUM $range dev $OVPN_DEV 2>/dev/null
    continue
  fi
#
  #dig A +short $line @localhost -p 53 | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | cut_local | awk '{system("ip route add table 1000 "$1" via 10.64.0.1 dev nwg1 2>/dev/null")}'
  nslookup $line $LOCAL_DNS | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local | grep -v $LOCAL_DNS | awk '{system("ip route add table "$TABLE_NUM" "$1" dev "$OVPN_DEV" 2>/dev/null")}'
#

done < $UNBLOCK_PATH/unblock.txt
echo "$(ip route show table $TABLE_NUM | wc -l) IPs are added to route table $TABLE_NUM."

exit 0