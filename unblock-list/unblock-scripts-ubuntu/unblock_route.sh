#!/usr/bin/env bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin

source /etc/openvpn/unblock/unblock-vars


[ "$script_type" ] || exit 0
[ "$dev" ] || exit 0

case "$script_type" in
  route-up)
    if [[ $(ip rule list | grep "lookup $TABLE_NUM") ]] || [[ $(ip rule list | grep "lookup $TABLE_NAME") ]]; then
    exit 0
    else
    # ip rule add table $TABLE_NUM priority 1777 2>/dev/null
    ip rule add table $TABLE_NUM 2>/dev/null
    fi
    $UNBLOCK_PATH/unblock_table.sh &
    ;;
  route-pre-down)
    ip rule del table $TABLE_NUM 2>/dev/null
    ;;
esac

exit 0