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
