#!/bin/bash

set -u

umask 077

timestamp="$(date +%Y%m%d-%H%M%S)"
output="${1:-/Volumes/F206/wifi-scan-diag-$timestamp.txt}"

section() {
    title="$1"
    shift
    printf '\n===== %s =====\n' "$title"
    "$@" 2>&1 || printf 'command failed: %s\n' "$*"
}

wifi_device() {
    networksetup -listallhardwareports | awk '
        /^Hardware Port:/ {
            hardware = $0
            sub(/^Hardware Port:[[:space:]]*/, "", hardware)
        }
        /^Device:/ {
            device = $0
            sub(/^Device:[[:space:]]*/, "", device)
            if (hardware == "Wi-Fi" || hardware == "AirPort") {
                print device
                exit
            }
        }
    '
}

WIFI_DEV="$(wifi_device)"

{
    section "time" date
    section "system" sw_vers
    section "kernel" uname -a
    section "hardware ports" networksetup -listallhardwareports
    section "service order" networksetup -listnetworkserviceorder
    section "services" networksetup -listallnetworkservices
    section "interfaces before" ifconfig -a
    section "network overview" scutil --nwi
    section "default route" route -n get default
    section "airport profiler" system_profiler SPAirPortDataType -detailLevel full

    printf '\n===== detected Wi-Fi device =====\n%s\n' "${WIFI_DEV:-missing}"

    if [ -n "$WIFI_DEV" ]; then
        section "Wi-Fi power before" networksetup -getairportpower "$WIFI_DEV"

        printf '\n===== toggle Wi-Fi power =====\n'
        networksetup -setairportpower "$WIFI_DEV" off 2>&1 || true
        sleep 2
        networksetup -setairportpower "$WIFI_DEV" on 2>&1 || true
        sleep 5

        section "Wi-Fi power after" networksetup -getairportpower "$WIFI_DEV"
        section "current Wi-Fi network" networksetup -getairportnetwork "$WIFI_DEV"
        section "interface after toggle" ifconfig "$WIFI_DEV"

        airport_bin="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
        if [ -x "$airport_bin" ]; then
            section "airport info" "$airport_bin" -I
            section "airport scan" "$airport_bin" -s
        else
            printf '\n===== airport scan =====\n'
            printf 'Apple80211 airport utility is not available on this build.\n'
        fi

        if command -v wdutil >/dev/null 2>&1; then
            section "wdutil info" wdutil info
        fi
    fi

    printf '\n===== loaded drivers =====\n'
    kmutil showloaded 2>/dev/null |
        grep -iE 'AirportItlwm|itlwm|IO80211|IOSkywalk|corecapture|Lilu' ||
        true

    printf '\n===== IORegistry Wi-Fi providers =====\n'
    ioreg -p IOService -l -w0 2>/dev/null |
        grep -i -B 12 -A 70 \
            -E 'AirportItlwm|itlwm|pci8086,2725|AppleIntelWiFi|IO80211' ||
        true

    printf '\n===== airportd service log =====\n'
    log show --last 15m --style compact \
        --predicate 'process == "airportd" OR process == "WiFiAgent" OR process == "ControlCenter"' \
        2>/dev/null | tail -500 || true

    printf '\n===== Wi-Fi driver and scan log =====\n'
    log show --last 15m --style compact \
        --predicate 'eventMessage CONTAINS[c] "AirportItlwm" OR eventMessage CONTAINS[c] "itlwm" OR eventMessage CONTAINS[c] "iwlwifi" OR eventMessage CONTAINS[c] "firmware" OR eventMessage CONTAINS[c] "80211" OR eventMessage CONTAINS[c] "scan"' \
        2>/dev/null | tail -800 || true
} > "$output" 2>&1

printf 'Wi-Fi diagnostic saved to %s\n' "$output"
