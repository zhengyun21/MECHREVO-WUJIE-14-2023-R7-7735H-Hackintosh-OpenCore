#!/usr/bin/env python3

import argparse
import copy
import hashlib
import os
import plistlib
import tempfile
from pathlib import Path


BOOT_PROVIDER = "7C436110-AB2A-4BBB-A880-FE41995C9F82"
BOOT_ARGS = (
    "-v -lilubetaall debug=0x100 keepsyms=1 -no_compat_check -no_restart "
    "amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 "
    "itlwm_he=1 kextlog=0xffff ocax210ref1"
)


def find_kext(entries, bundle_path):
    matches = [entry for entry in entries if entry.get("BundlePath") == bundle_path]
    if len(matches) != 1:
        raise ValueError(
            f"expected exactly one {bundle_path} entry, found {len(matches)}"
        )
    return matches[0]


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("reference", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    with args.source.open("rb") as handle:
        config = plistlib.load(handle)
    with args.reference.open("rb") as handle:
        reference = plistlib.load(handle)

    entries = config.get("Kernel", {}).get("Add", [])
    reference_entries = reference.get("Kernel", {}).get("Add", [])

    lilu = find_kext(entries, "Lilu.kext")
    itlwm = find_kext(entries, "itlwm.kext")
    current_airport = find_kext(entries, "AirportItlwm.kext")
    reference_airport = copy.deepcopy(
        find_kext(reference_entries, "AirportItlwm.kext")
    )
    reference_amfipass = copy.deepcopy(
        find_kext(reference_entries, "AMFIPass.kext")
    )

    if not lilu.get("Enabled"):
        raise ValueError("Lilu.kext must remain enabled")

    itlwm["Enabled"] = False
    reference_airport["Enabled"] = True
    reference_amfipass["Enabled"] = True

    airport_index = entries.index(current_airport)
    entries[airport_index] = reference_airport
    entries[:] = [
        entry
        for entry in entries
        if entry.get("BundlePath") != "AMFIPass.kext"
    ]
    lilu_index = next(
        index
        for index, entry in enumerate(entries)
        if entry.get("BundlePath") == "Lilu.kext"
    )
    entries.insert(lilu_index + 1, reference_amfipass)

    nvram = config.setdefault("NVRAM", {}).setdefault("Add", {})
    provider = nvram.setdefault(BOOT_PROVIDER, {})
    provider["boot-args"] = BOOT_ARGS.encode("utf-8")
    provider["csr-active-config"] = bytes.fromhex("ff0f0000")
    config.setdefault("Misc", {}).setdefault("Security", {})[
        "SecureBootModel"
    ] = "Disabled"

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
        "AMFIPass.kext": True,
        "itlwm.kext": False,
        "AirportItlwm.kext": True,
    }
    for bundle_path, expected in checks.items():
        actual = find_kext(generated_entries, bundle_path).get("Enabled")
        if actual is not expected:
            raise ValueError(
                f"{bundle_path} generated Enabled={actual}, expected {expected}"
            )

    provider = generated["NVRAM"]["Add"][BOOT_PROVIDER]
    if provider["boot-args"].decode("utf-8") != BOOT_ARGS:
        raise ValueError("boot arguments do not match the rescue profile")
    if provider["csr-active-config"].hex() != "ff0f0000":
        raise ValueError("SIP configuration does not match the reference")

    print(f"source_sha256={sha256(args.source)}")
    print(f"reference_sha256={sha256(args.reference)}")
    print(f"generated_sha256={sha256(args.output)}")
    print("itlwm.kext=False")
    print("AMFIPass.kext=True")
    print("AirportItlwm.kext=True")
    print(f"boot-args={BOOT_ARGS}")


if __name__ == "__main__":
    main()
