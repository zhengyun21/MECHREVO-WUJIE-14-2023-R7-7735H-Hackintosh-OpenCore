# Third-Party Notices

本仓库包含的二进制组件（`EFI/OC/Kexts`、`EFI/OC/Drivers`、`EFI/OC/Tools`、`EFI/OC/Resources`、`Radeonized/RBAMDFramebuffer.kext`）来自下列上游项目，按各自许可证分发。完整许可证文本请以各上游仓库为准；GPL 组件的对应源码可通过下列链接获取。

| 组件 | 许可证 | 上游源码 |
|---|---|---|
| OpenCore / OpenRuntime / OpenVariableRuntimeDxe / OpenHfsPlus / OpenCanopy / ResetNvramEntry | BSD-3-Clause | https://github.com/acidanthera/OpenCorePkg |
| Lilu | BSD-3-Clause | https://github.com/acidanthera/Lilu |
| VirtualSMC / SMCBatteryManager | BSD-3-Clause | https://github.com/acidanthera/VirtualSMC |
| NVMeFix | BSD-3-Clause | https://github.com/acidanthera/NVMeFix |
| RestrictEvents | BSD-3-Clause | https://github.com/acidanthera/RestrictEvents |
| BrightnessKeys | BSD-3-Clause | https://github.com/acidanthera/BrightnessKeys |
| AppleMCEReporterDisabler | BSD-3-Clause | https://github.com/acidanthera/AppleMCEReporterDisabler |
| AppleALC（本配置关闭） | BSD-3-Clause | https://github.com/acidanthera/AppleALC |
| VoodooPS2Controller / VoodooInput 1.1.6 | BSD-3-Clause | https://github.com/acidanthera/VoodooPS2 · https://github.com/acidanthera/VoodooInput |
| AMFIPass | MIT | https://github.com/dhinakg/AMFIPass |
| USBToolBox / UTBMap | MIT | https://github.com/USBToolBox/kext |
| **RembrandtGPU / RBAMDFramebuffer（Radeonized v0.1.1）** | **MIT（代码）+ AMD 微码二进制许可** | https://github.com/FranciumOS-org/Radeonized |
| RembrandtGfx 0.1.0（本分支 Disabled，仅回退参考） | **GPL-2.0** | https://github.com/caoshiyuan0211-blip/winmax2-2022-6800u-hackintosh |
| AirportItlwm（AWDL 构建） | GPL-2.0 | https://github.com/kevineduardo/ax210-airdrop-awdl-hackintosh （fork of OpenIntelWireless/itlwm） |
| IntelBluetoothFirmware / IntelBTPatcher | **GPL-3.0** | https://github.com/OpenIntelWireless/IntelBluetoothFirmware |
| BlueToolFixup（advsets 构建） | GPL-2.0 | https://github.com/kevineduardo/ax210-airdrop-awdl-hackintosh （fork of acidanthera/BrcmPatchRAM） |
| VoodooI2C / VoodooI2CHID / VoodooGPIO / VoodooI2CServices | **GPL-3.0** | https://github.com/VoodooI2C/VoodooI2C |
| VoodooHDA | GPL-2.0 | 上游 VoodooHDA 项目 |
| AmdTscSync | 见上游 | 上游 AmdTscSync 项目 |

## Radeonized / AMD 微码

- `RembrandtGPU.kext` 与 `RBAMDFramebuffer.kext` 的代码为 MIT：`Copyright (c) 2026 RembrandtGPU contributors`，完整文本见 `Radeonized/LICENSE`。
- `RembrandtGPU.kext` 内嵌 AMD 微码；按 `Radeonized/LICENSE.amdgpu` **仅允许二进制形式再分发**，禁止反向工程/反编译/反汇编，必须随附版权、许可与免责声明。`RembrandtGPU.kext/Contents/Resources/LICENSE.amdgpu` 必须保留，不要剥离。
- 上游的 `Radeonized/THIRD-PARTY.md` 说明了二进制携带的内容；本仓库原样收录。
- 上游 release 本身未携带 MIT 文本，本仓库已补 `Radeonized/LICENSE`。

## GPL 说明

- 对于 GPL-2.0 / GPL-3.0 组件，本仓库仅按原样再分发二进制；对应源码请通过上表链接获取（上游仓库或发布页）。
- 本仓库原创的文档、脚本与配置使用 MIT（见 `LICENSE`）；MIT 不改变第三方二进制自身的许可证。
- Radeonized 的 MIT 代码与 AMD 微码许可独立于本仓库 MIT；不要将它们重新许可为 GPL 或本仓库 MIT。

## 不包含的内容

- Apple 系统文件、macOS 安装镜像、AMD VBIOS（`ATY,bin_image`）、真实 SMBIOS 序列号/MLB/UUID/ROM、OpenCore 日志、NVRAM 转储、config 备份。
- 本分支已在 tip 移除 main 上遗留的两个 `config.before-*.plist`；但 main 历史/fork/缓存仍可能保留旧对象，旧三码请视为已泄露。
