#!/usr/bin/env python3

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
    return digest.hexdigest().upper()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    with args.source.open("rb") as handle:
        config = plistlib.load(handle)

    generic = config.get("PlatformInfo", {}).get("Generic")
    if not isinstance(generic, dict):
        raise ValueError("PlatformInfo/Generic is missing")

    for field in SENSITIVE_FIELDS:
        if field not in generic:
            raise ValueError(f"PlatformInfo/Generic/{field} is missing")
        current = generic[field]
        if isinstance(current, bytes):
            generic[field] = b""
        else:
            generic[field] = ""

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

    print(f"source_sha256={sha256(args.source)}")
    print(f"sanitized_sha256={sha256(args.output)}")
    print("SystemProductName=" + str(sanitized_generic.get("SystemProductName", "")))
    print("sensitive_fields=empty")


if __name__ == "__main__":
    main()
