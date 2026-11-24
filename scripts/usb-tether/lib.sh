#!/bin/sh

list_usb_ethernet_ports() {
    networksetup -listallhardwareports | awk '
        /^Hardware Port:/ {
            hardware = $0
            sub(/^Hardware Port:[[:space:]]*/, "", hardware)
        }
        /^Device:/ {
            device = $0
            sub(/^Device:[[:space:]]*/, "", device)
            if (hardware ~ /(USB|RNDIS|Android|NCM)/) {
                print device "\t" hardware
            }
        }
    '
}

find_network_service_for_device() {
    device="$1"
    networksetup -listnetworkserviceorder | awk -v wanted="$device" '
        /^\([0-9]+\) / {
            service = $0
            sub(/^\([0-9]+\)[[:space:]]*/, "", service)
        }
        !found && index($0, "Device: " wanted ")") {
            print service
            found = 1
        }
        END {
            if (!found) {
                exit 1
            }
        }
    '
}

discover_usb_ethernet() {
    ports="$(list_usb_ethernet_ports)" || return 1
    tab="$(printf '\t')"
    result=""
    count=0

    while IFS="$tab" read -r device hardware; do
        [ -n "$device" ] || continue
        service="$(find_network_service_for_device "$device")" || continue
        count=$((count + 1))
        result="${service}${tab}${device}${tab}${hardware}"
    done <<EOF
$ports
EOF

    if [ "$count" -eq 0 ]; then
        return 2
    fi
    if [ "$count" -gt 1 ]; then
        return 3
    fi
    printf '%s\n' "$result"
}
