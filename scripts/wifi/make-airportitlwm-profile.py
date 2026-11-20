#!/usr/bin/env python3

import argparse
import hashlib
import os
import plistlib
import re
import tempfile
from pathlib import Path


def find_kext(entries, bundle_path):
    matches = [entry for entry in entries if entry.get("BundlePath") == bundle_path]
    if len(matches) != 1:
        raise ValueError(
            f"expected exactly one {bundle_path} entry, found {len(matches)}"
        )
    return matches[0]


def read_boot_args(config):
    providers = config.get("NVRAM", {}).get("Add", {})
    provider = providers.get("7C436110-AB2A-4BBB-A880-FE41995C9F82", {})
    return provider, provider.get("boot-args", b"")


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--marker", default="ocairport1")
    args = parser.parse_args()

    with args.source.open("rb") as handle:
        config = plistlib.load(handle)

    entries = config.get("Kernel", {}).get("Add", [])
    lilu = find_kext(entries, "Lilu.kext")
    itlwm = find_kext(entries, "itlwm.kext")
    airport = find_kext(entries, "AirportItlwm.kext")

    if not lilu.get("Enabled"):
        raise ValueError("Lilu.kext must remain enabled")
    if not airport.get("MinKernel"):
        raise ValueError("AirportItlwm.kext must declare MinKernel")

    itlwm["Enabled"] = False
    airport["Enabled"] = True

    provider, boot_args = read_boot_args(config)
    text = boot_args.decode("utf-8", "replace")
    text = re.sub(r"(?:^|\s)oc(?:itlwm|airport|nwi)\w*(?=\s|$)", "", text)
    text = " ".join([text.strip(), args.marker]).strip()
    provider["boot-args"] = text.encode("utf-8")

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
        generated = plistlib.load(handle)
    generated_entries = generated.get("Kernel", {}).get("Add", [])
    checks = {
        "Lilu.kext": True,
        "itlwm.kext": False,
        "AirportItlwm.kext": True,
    }
    for bundle_path, expected in checks.items():
        actual = find_kext(generated_entries, bundle_path).get("Enabled")
        if actual is not expected:
            raise ValueError(
                f"{bundle_path} generated Enabled={actual}, expected {expected}"
            )

    _, generated_args = read_boot_args(generated)
    if not generated_args.decode("utf-8", "replace").endswith(args.marker):
        raise ValueError("boot marker was not appended")

    print(f"source_sha256={sha256(args.source)}")
    print(f"generated_sha256={sha256(args.output)}")
    print("itlwm.kext=False")
    print("AirportItlwm.kext=True")
    print(f"marker={args.marker}")


if __name__ == "__main__":
    main()
