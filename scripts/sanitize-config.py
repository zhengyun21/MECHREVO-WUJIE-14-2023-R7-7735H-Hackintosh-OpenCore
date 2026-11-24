#!/usr/bin/env python3
"""Sanitize an OpenCore config.plist before publishing it.

- blanks SystemSerialNumber / MLB / SystemUUID / ROM
- removes the machine-specific ATY,bin_image VBIOS blob
- removes Kernel -> Add entries whose bundle is not shipped in EFI/OC/Kexts

Usage:
  ./scripts/sanitize-config.py EFI/OC/config.plist EFI/OC/config.plist
  ./scripts/sanitize-config.py working.plist public.plist --keep-vbios
"""

import argparse
import hashlib
import os
import plistlib
import tempfile
from pathlib import Path

SENSITIVE_FIELDS = (
    "SystemSerialNumber",
    "MLB",
    "SystemUUID",
    "ROM",
)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def strip_vbios(config):
    removed = 0
    for _, props in config.get("DeviceProperties", {}).get("Add", {}).items():
        if isinstance(props, dict) and "ATY,bin_image" in props:
            removed += len(props.pop("ATY,bin_image"))
    return removed


def prune_dangling_kexts(config, kexts_dir):
    entries = config.get("Kernel", {}).get("Add", [])
    kept, dropped = [], []
    for entry in entries:
        bundle = entry.get("BundlePath", "")
        if bundle and (kexts_dir / bundle).is_dir():
            kept.append(entry)
        else:
            dropped.append(bundle)
    config.setdefault("Kernel", {})["Add"] = kept
    return dropped


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--keep-vbios", action="store_true")
    parser.add_argument("--keep-dangling", action="store_true")
    parser.add_argument("--kexts-dir", type=Path, default=None)
    args = parser.parse_args()

    with args.source.open("rb") as handle:
        config = plistlib.load(handle)

    generic = config.get("PlatformInfo", {}).get("Generic")
    if not isinstance(generic, dict):
        raise ValueError("PlatformInfo/Generic is missing")

    for field in SENSITIVE_FIELDS:
        if field not in generic:
            raise ValueError(f"PlatformInfo/Generic/{field} is missing")
        generic[field] = b"" if isinstance(generic[field], bytes) else ""

    vbios_bytes = 0 if args.keep_vbios else strip_vbios(config)

    dropped = []
    if not args.keep_dangling:
        kexts_dir = args.kexts_dir or args.output.parent / "Kexts"
        if kexts_dir.is_dir():
            dropped = prune_dangling_kexts(config, kexts_dir)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        dir=args.output.parent, prefix=args.output.name + ".", delete=False
    ) as handle:
        temp_path = Path(handle.name)
        plistlib.dump(config, handle, sort_keys=False)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temp_path, args.output)

    with args.output.open("rb") as handle:
        sanitized = plistlib.load(handle)
    sanitized_generic = sanitized["PlatformInfo"]["Generic"]
    for field in SENSITIVE_FIELDS:
        if sanitized_generic[field] not in ("", b""):
            raise ValueError(f"{field} was not sanitized")
    if not args.keep_vbios:
        for props in sanitized.get("DeviceProperties", {}).get("Add", {}).values():
            if isinstance(props, dict) and "ATY,bin_image" in props:
                raise ValueError("ATY,bin_image was not removed")

    print(f"source_sha256={sha256(args.source)}")
    print(f"sanitized_sha256={sha256(args.output)}")
    print("SystemProductName=" + str(sanitized_generic.get("SystemProductName", "")))
    print("sensitive_fields=empty")
    print(f"removed_vbios_bytes={vbios_bytes}")
    print(f"dropped_kext_entries={len(dropped)}")
    for bundle in dropped:
        print(f"  dropped: {bundle}")


if __name__ == "__main__":
    main()
