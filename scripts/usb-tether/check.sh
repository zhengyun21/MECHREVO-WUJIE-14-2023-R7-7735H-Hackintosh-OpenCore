#!/bin/sh

set -u

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

record="$(discover_usb_ethernet)"
status=$?
if [ "$status" -eq 2 ]; then
    echo "FAIL: no USB Ethernet service found"
    exit 2
fi
if [ "$status" -eq 3 ]; then
    echo "FAIL: multiple USB Ethernet services found; refusing to guess"
    exit 2
fi
if [ "$status" -ne 0 ]; then
    echo "FAIL: USB Ethernet discovery failed"
    exit 2
fi

service="$(printf '%s\n' "$record" | cut -f1)"
device="$(printf '%s\n' "$record" | cut -f2)"
hardware="$(printf '%s\n' "$record" | cut -f3)"

enabled="$(networksetup -getnetworkserviceenabled "$service" 2>/dev/null)"
ipv4="$(ifconfig "$device" 2>/dev/null | awk '$1 == "inet" { print $2; exit }')"
default_device="$(
    route -n get default 2>/dev/null |
    awk '/interface:/ { print $2; exit }'
)"

if dscacheutil -q host -a name captive.apple.com 2>/dev/null |
    grep -q '^ip_address:'; then
    dns="PASS"
else
    dns="FAIL"
fi

if curl -fsS --max-time 8 \
    https://captive.apple.com/hotspot-detect.html 2>/dev/null |
    grep -qi 'Success'; then
    internet="PASS"
else
    internet="FAIL"
fi

printf 'service=%s\n' "$service"
printf 'hardware=%s\n' "$hardware"
printf 'device=%s\n' "$device"
printf 'service_enabled=%s\n' "$enabled"
printf 'ipv4=%s\n' "${ipv4:-missing}"
printf 'default_interface=%s\n' "${default_device:-missing}"
printf 'dns=%s\n' "$dns"
printf 'internet=%s\n' "$internet"

if [ "$enabled" != "enabled" ]; then
    echo "FAIL: network service is disabled"
    exit 3
fi
if [ -z "$ipv4" ]; then
    echo "FAIL: USB interface has no IPv4 address"
    exit 3
fi
if [ "$default_device" != "$device" ]; then
    echo "FAIL: default route is not using the USB interface"
    exit 3
fi
if [ "$dns" != "PASS" ] || [ "$internet" != "PASS" ]; then
    echo "FAIL: DNS or Internet request failed"
    exit 4
fi

echo "PASS: USB tether is connected and usable"
