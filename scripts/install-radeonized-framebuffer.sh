#!/bin/sh
# Install the Radeonized framebuffer kext into /Library/Extensions and rebuild
# the auxiliary kernel collection, with dry-run, backup and UUID verification.
#
#   sudo ./scripts/install-radeonized-framebuffer.sh
#
# The source bundle is Radeonized/RBAMDFramebuffer.kext in this repository.
set -eu

log() { printf '%s\n' "$*"; }

[ "$(id -u)" = 0 ] || { log "run with sudo: sudo $0" >&2; exit 1; }

root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/Radeonized/RBAMDFramebuffer.kext"
bin="$src/Contents/MacOS/RBAMDFramebuffer"
live=/Library/KernelCollections/AuxiliaryKernelExtensions.kc
boot=/System/Library/KernelCollections/BootKernelExtensions.kc
sys=/System/Library/KernelCollections/SystemKernelExtensions.kc
scratch=/private/var/tmp/aux-radeonized.kc
expected=31B2C56B-0FC6-3F8F-85C1-7DD4A2FBAFA1

[ -d "$src" ] || { log "!! missing $src" >&2; exit 1; }
[ -f "$bin" ] || { log "!! missing $bin" >&2; exit 1; }
[ -f "$live" ] || { log "!! missing $live" >&2; exit 1; }
[ -f "$boot" ] && [ -f "$sys" ] || { log "!! missing boot/system kernel collection" >&2; exit 1; }

major="$(sw_vers -productVersion | cut -d. -f1)"
case "$major" in
    15|26) ;;
    *) log "warning: Radeonized is measured on macOS 15 and 26; this is macOS $major" ;;
esac

uuid="$(dwarfdump --uuid "$bin" | awk '{print $2}')"
[ -n "$uuid" ] || { log "!! could not read UUID from $bin" >&2; exit 1; }
log "RBAMDFramebuffer UUID: $uuid"
[ "$uuid" = "$expected" ] || log "warning: expected $expected, got $uuid"

log "staging into /Library/Extensions"
rm -rf /Library/Extensions/RBAMDFramebuffer.kext
cp -R "$src" /Library/Extensions/
chown -R root:wheel /Library/Extensions/RBAMDFramebuffer.kext
chmod 755 /Library/Extensions/RBAMDFramebuffer.kext/Contents/MacOS/RBAMDFramebuffer

log "dry run -> $scratch"
rm -f "$scratch"
kmutil create -n aux -a x86_64 --allow-missing-kdk \
    -B "$boot" -S "$sys" -A "$scratch" -r /Library/Extensions >/dev/null
[ -s "$scratch" ] || { log "!! dry run wrote nothing; live collection untouched" >&2; exit 1; }
if ! kmutil inspect -B "$scratch" --show-kext-uuids 2>/dev/null | grep -qi "$uuid"; then
    log "!! dry-run collection does not carry $uuid" >&2
    kmutil inspect -B "$scratch" --show-kext-uuids 2>/dev/null | grep -i rembrandt >&2 || true
    exit 1
fi
log "dry run carries $uuid"

backup="$live.bak-$(date +%Y%m%d-%H%M%S)"
cp -p "$live" "$backup"
log "backed up live collection -> $backup"

log "writing $live"
kmutil create -n aux -a x86_64 --allow-missing-kdk \
    -B "$boot" -S "$sys" -A "$live" -r /Library/Extensions >/dev/null

if kmutil inspect -B "$live" --show-kext-uuids 2>/dev/null | grep -qi "$uuid"; then
    rm -f "$scratch"
    log "INSTALLED: live aux KC carries $uuid"
    log "Reboot, then verify with:"
    log "  system_profiler SPDisplaysDataType"
    log "  ioreg -rl -c RembrandtGPUPeer | tr ',' '\\n' | grep -E '\"(armed|arm_why|vbios_src|acpivbios)\"='"
    exit 0
fi

log "!! live collection does not carry $uuid; restoring backup" >&2
cp -p "$backup" "$live"
exit 1
