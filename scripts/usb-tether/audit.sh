#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

umask 077
timestamp="$(date +%Y%m%d-%H%M%S)"
output="${1:-/tmp/usb-tether-audit-$timestamp.txt}"
raw="$(mktemp "${TMPDIR:-/tmp}/usb-tether-audit.XXXXXX")"
trap 'rm -f "$raw"' EXIT INT TERM

section() {
    title="$1"
    shift
    printf '\n===== %s =====\n' "$title"
    "$@" 2>&1 || printf 'command failed: %s\n' "$*"
}

{
    section "system" sw_vers
    section "kernel" uname -a
    section "hardware ports" networksetup -listallhardwareports
    section "service order" networksetup -listnetworkserviceorder
    section "services" networksetup -listallnetworkservices
    section "interfaces" ifconfig -a
    section "network overview" scutil --nwi
    section "default route" route -n get default
    section "IPv4 routes" netstat -rn -f inet

    printf '\n===== service settings =====\n'
    networksetup -listallnetworkservices | tail -n +2 |
    while IFS= read -r service; do
        service="${service#\*}"
        printf '\n--- %s ---\n' "$service"
        networksetup -getinfo "$service" 2>&1 ||
            printf 'getinfo failed\n'
        networksetup -getnetworkserviceenabled "$service" 2>&1 ||
            printf 'enabled-state failed\n'
        networksetup -getdnsservers "$service" 2>&1 ||
            printf 'dns-state failed\n'
    done

    printf '\n===== USB devices =====\n'
    ioreg -p IOService -r -c IOUSBHostDevice -d 1 2>/dev/null |
        grep -E '"USB Product Name"|"USB Vendor Name"|"idVendor"|"idProduct"|"locationID"' ||
        true

    printf '\n===== functional check =====\n'
    "$SCRIPT_DIR/check.sh" 2>&1 || true
} > "$raw" 2>&1

sed -E \
    -e 's/([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}/<redacted-mac>/g' \
    "$raw" | tee "$output"

printf '\nReport saved to %s\n' "$output"
