# Third-party material redistributed by this project

## AMD microcode (`amdgpu` / yellow_carp)

The plugin binary carries the signed GC 10.3, RLC, SDMA and PSP TOC microcode
images for Rembrandt, taken from
[linux-firmware](https://gitlab.com/kernel-firmware/linux-firmware)
(`amdgpu/yellow_carp_*.bin`, fetched 2026-10-05). They are compiled into
`src/plugin/fw_yellow_carp.cpp` and `src/plugin/fw_yellow_carp_rlc.cpp` and are
substituted for Apple's Navi 21 images at `_IpiSetFwEntry`, which is what lets
the PSP bring up this chip.

They are redistributed under AMD's own licence, reproduced verbatim in
[`LICENSE.amdgpu`](LICENSE.amdgpu), as that licence requires. In summary, it
permits installing, reproducing, copying and distributing the microcode **in
binary form only**, free of licence fees, provided that no reverse engineering,
decompilation or disassembly of the microcode is performed and that the
copyright notice, permission notice and disclaimers are reproduced in the
accompanying materials. The microcode is provided by AMD **as is and without
warranty of any kind**; see `LICENSE.amdgpu` for the full disclaimers and for
the United States export-control notice, both of which apply to anyone
redistributing this project's binaries.

Nothing in this project reverse engineers, decompiles or disassembles the AMD
microcode: the images are moved as opaque bytes.

A build made with `NOFW=1` omits them, but **that build is not expected to
accelerate** — boot 542 measured `yc_swapped 12`, so the images are consumed
twelve times on an accelerated boot and are functionally required, not ballast.

**What the binary carries is each image's payload** — the bytes at
`ucode_array_offset` (0x100) for `ucode_size_bytes` — rather than the whole
`.bin` file including its container header, because that payload is exactly
what the PSP is handed. AMD's licence sets no condition about distributing the
files unmodified; it grants distribution of copies in binary form.
