# USB Tether Automatic Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans
> to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax
> for tracking.

**Goal:** Prove whether the already-working iQOO Z8 USB network share recovers
automatically after reboot, replug, and wake without changing the USB map.

**Architecture:** Add three read-only macOS scripts that discover the USB
Ethernet service by hardware-port data, inspect its DHCP state, and verify
actual Internet access. Run the scripts before and after physical restart and
replug tests. A persistent recovery daemon is only designed if these tests
produce a reproducible failure, as required by the approved specification.

**Tech Stack:** macOS 15 shell tools (`networksetup`, `ifconfig`, `ipconfig`,
`scutil`, `route`, `dscacheutil`, `curl`), POSIX shell, mocked command tests,
physical reboot and USB replug acceptance.

---

## Scope Boundary

This plan implements the evidence-gathering and native auto-recovery test
gate. It does not modify UTBMap, OpenCore, USB kexts, DHCP settings, network
service order, or macOS system files.

If Task 6 records a reproducible failure, create a second implementation plan
for the narrowly scoped launchd recovery task described in the approved design.
Do not install that task before the failure is captured.

## File Structure

- Create: `scripts/usb-tether/lib.sh`
  - Owns USB Ethernet discovery and interface-to-service mapping.
- Create: `scripts/usb-tether/audit.sh`
  - Produces a redacted, read-only baseline report.
- Create: `scripts/usb-tether/check.sh`
  - Performs one functional USB-tether connectivity check.
- Create: `scripts/usb-tether/test.sh`
  - Tests discovery with mocked `networksetup` output.
- Create: `docs/usb-tether/2026-11-20-baseline-result.md`
  - Records physical test outcomes after the macOS runs.

## Task 1: Add Failing Tests For USB Ethernet Discovery

**Files:**
- Create: `scripts/usb-tether/test.sh`
- Test: `scripts/usb-tether/test.sh`

- [ ] **Step 1: Create the failing test script**

```sh
#!/bin/bash

set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"

for required in lib.sh audit.sh check.sh; do
    if [ ! -f "$ROOT/$required" ]; then
        echo "FAIL: missing $required"
        exit 1
    fi
done

TMP="$(mktemp -d "${TMPDIR:-/tmp}/usb-tether-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT INT TERM

BIN="$TMP/bin"
mkdir -p "$BIN"
export MOCK_HW="$TMP/hardware-ports.txt"
export MOCK_ORDER="$TMP/service-order.txt"

cat > "$BIN/networksetup" <<'MOCK'
#!/bin/sh
case "$1" in
    -listallhardwareports)
        cat "$MOCK_HW"
        ;;
    -listnetworkserviceorder)
        cat "$MOCK_ORDER"
        ;;
    *)
        exit 1
        ;;
esac
MOCK
chmod +x "$BIN/networksetup"

export PATH="$BIN:/usr/bin:/bin:/usr/sbin:/sbin"
. "$ROOT/lib.sh"

cat > "$MOCK_HW" <<'DATA'
Hardware Port: Wi-Fi
Device: en0
Ethernet Address: 00:11:22:33:44:55

Hardware Port: USB Ethernet
Device: en7
Ethernet Address: 66:77:88:99:aa:bb
DATA

cat > "$MOCK_ORDER" <<'DATA'
(1) Wi-Fi
(Hardware Port: Wi-Fi, Device: en0)
(2) iQOO Z8
(Hardware Port: USB Ethernet, Device: en7)
DATA

expected="$(printf 'iQOO Z8\ten7\tUSB Ethernet')"
actual="$(discover_usb_ethernet)" || {
    echo "FAIL: unique USB Ethernet service was not discovered"
    exit 1
}
if [ "$actual" != "$expected" ]; then
    echo "FAIL: discovery output mismatch"
    printf 'expected: %s\nactual:   %s\n' "$expected" "$actual"
    exit 1
fi

cat > "$MOCK_HW" <<'DATA'
Hardware Port: Wi-Fi
Device: en0
Ethernet Address: 00:11:22:33:44:55

Hardware Port: USB Ethernet
Device: en7
Ethernet Address: 66:77:88:99:aa:bb

Hardware Port: USB 10/100/1000 LAN
Device: en8
Ethernet Address: aa:bb:cc:dd:ee:ff
DATA

cat > "$MOCK_ORDER" <<'DATA'
(1) Wi-Fi
(Hardware Port: Wi-Fi, Device: en0)
(2) iQOO Z8
(Hardware Port: USB Ethernet, Device: en7)
(3) USB LAN
(Hardware Port: USB 10/100/1000 LAN, Device: en8)
DATA

discover_usb_ethernet >/dev/null
status=$?
if [ "$status" -ne 3 ]; then
    echo "FAIL: multiple USB Ethernet devices must be rejected"
    exit 1
fi

echo "PASS: USB Ethernet discovery tests"
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```sh
sh scripts/usb-tether/test.sh
```

Expected:

```text
FAIL: missing lib.sh
```

## Task 2: Implement Read-Only Discovery And Checks

**Files:**
- Create: `scripts/usb-tether/lib.sh`
- Create: `scripts/usb-tether/audit.sh`
- Create: `scripts/usb-tether/check.sh`

- [ ] **Step 1: Implement USB Ethernet discovery**

```sh
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
```

- [ ] **Step 2: Implement the baseline report**

```sh
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
```

- [ ] **Step 3: Implement the functional check**

```sh
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

tab="$(printf '\t')"
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
```

- [ ] **Step 4: Make the scripts executable**

Run:

```sh
chmod +x scripts/usb-tether/audit.sh scripts/usb-tether/check.sh \
    scripts/usb-tether/test.sh
```

## Task 3: Run Static And Mocked Tests

**Files:**
- Test: `scripts/usb-tether/lib.sh`
- Test: `scripts/usb-tether/audit.sh`
- Test: `scripts/usb-tether/check.sh`
- Test: `scripts/usb-tether/test.sh`

- [ ] **Step 1: Run shell syntax checks**

Run:

```sh
bash -n scripts/usb-tether/lib.sh
bash -n scripts/usb-tether/audit.sh
bash -n scripts/usb-tether/check.sh
bash -n scripts/usb-tether/test.sh
```

Expected: all commands exit with status 0 and print nothing.

- [ ] **Step 2: Run discovery tests**

Run:

```sh
bash scripts/usb-tether/test.sh
```

Expected:

```text
PASS: USB Ethernet discovery tests
```

- [ ] **Step 3: Commit the read-only tooling**

Run:

```sh
git add scripts/usb-tether docs/superpowers/plans/2026-11-20-usb-tether-autorecovery.md
git commit -m "test: add USB tether auto-recovery diagnostics"
```

Expected: one commit containing the plan and read-only scripts.

## Task 4: Record The Initial macOS Baseline

**Files:**
- Create: `docs/usb-tether/2026-11-20-baseline-result.md`

- [ ] **Step 1: Copy the directory `scripts/usb-tether` to the FAT32 USB volume.**

The expected mounted path inside macOS is:

```text
/Volumes/OPENCORE/usb-tether
```

- [ ] **Step 2: In macOS, verify the visible service before changing anything**

Run:

```sh
networksetup -listallhardwareports
networksetup -listnetworkserviceorder
```

Expected: exactly one hardware port whose name contains `USB`, `RNDIS`,
`Android`, or `NCM`, with a corresponding named network service.

- [ ] **Step 3: Run the read-only audit**

Turn Wi-Fi off and disconnect any VPN before these checks so the test proves
that traffic is using the USB tether.

Run:

```sh
sh /Volumes/OPENCORE/usb-tether/audit.sh \
    /Volumes/OPENCORE/usb-tether-audit-before-reboot.txt
sh /Volumes/OPENCORE/usb-tether/check.sh
```

Expected:

```text
PASS: USB tether is connected and usable
```

Record the service name, hardware-port name, device name, IPv4 state, default
interface, DNS result, and Internet result in the baseline result file.

## Task 5: Run Reboot, Replug, And Wake Acceptance

**Files:**
- Modify: `docs/usb-tether/2026-11-20-baseline-result.md`

- [ ] **Step 1: Reboot macOS with the phone connected and tethering enabled.**
- [ ] **Step 2: Log in, wait up to 60 seconds, then run the check.**

Run:

```sh
sh /Volumes/OPENCORE/usb-tether/check.sh
```

Expected:

```text
PASS: USB tether is connected and usable
```

- [ ] **Step 3: Unplug the phone, wait 10 seconds, and reconnect it with tethering enabled.**
- [ ] **Step 4: Wait up to 60 seconds, then run the check again.**

Run:

```sh
sh /Volumes/OPENCORE/usb-tether/check.sh
```

Expected:

```text
PASS: USB tether is connected and usable
```

- [ ] **Step 5: Record each exact failure status when a check does not pass.**

Exit status meanings:

```text
2: USB Ethernet service discovery failed or was ambiguous
3: interface, service, IPv4, or default route state was incomplete
4: DNS or HTTP connectivity failed
```

- [ ] **Step 6: Put macOS to sleep, wake it, wait up to 60 seconds, and repeat the check.**

Run:

```sh
sh /Volumes/OPENCORE/usb-tether/check.sh
```

Expected:

```text
PASS: USB tether is connected and usable
```

- [ ] **Step 7: Confirm the wired mouse still moves and a USB storage device still enumerates when one is available.**

Expected: no USB device disappears or reconnects repeatedly during the tether
checks.

## Task 6: Decision Gate And Archive

**Files:**
- Modify: `docs/usb-tether/2026-11-20-baseline-result.md`

- [ ] **Step 1: If the initial, reboot, replug, and wake checks all pass, record that no system changes are needed.**

Expected decision text:

```text
Native macOS auto-recovery passed reboot, replug, and wake tests.
No launchd task, UTBMap change, or OpenCore change is required.
```

- [ ] **Step 2: If a check fails reproducibly, record the failing stage and keep all system settings unchanged.**

Expected decision text:

```text
Native macOS auto-recovery failed in the recorded test.
The failed step and exit status are listed in the test transcript above.
Create a separate evidence-backed plan for the launchd recovery task.
```

- [ ] **Step 3: Confirm the USB map and config hashes did not change**

Run in Windows after reconnecting the USB:

```powershell
Get-FileHash `
  'D:\macOS-Offline\F206-backup-20261115\EFI\OC\config.plist' `
  -Algorithm SHA256
Get-FileHash `
  'D:\macOS-Offline\F206-backup-20261115\EFI\OC\Kexts\UTBMap.kext\Contents\Info.plist' `
  -Algorithm SHA256
```

Expected:

```text
OpenCore config: 0BDC440768259F6EC3F402D90F095AD0301A1818BC5B732E636BED5FA3394FC7
144C63C9CA3D6F07FEC32E3D28B6F1CB2B5061CCAACC8F2BC1461C0E7DC1152C
```

- [ ] **Step 4: Commit the recorded result**

Run:

```sh
git add docs/usb-tether/2026-11-20-baseline-result.md
git commit -m "record: USB tether native auto-recovery results"
```

Expected: one commit containing only the physical test result.
