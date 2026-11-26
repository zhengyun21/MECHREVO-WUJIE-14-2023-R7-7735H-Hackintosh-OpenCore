# 组件与许可证

以下为 `EFI/OC/Kexts` 与 `Radeonized/` 中随仓库分发的组件。版本来自各 `Info.plist`。许可证按上游仓库标注，**最终以上游 `LICENSE` 为准**；GPL 组件的对应源码请到上游仓库获取。

> 本分支（`radeonized-680m`）的显卡方案为 Radeonized v0.1.1；`main` 的 RembrandtGfx 方案仅作为回退参考。
> 本仓库原创文档/配置为 MIT；第三方二进制仍受各自许可证约束，见 [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)。

## 引导器

| 组件 | 版本 | 上游 | 许可证 |
|---|---|---|---|
| OpenCore | 1.0.8（按现有记录） | <https://github.com/acidanthera/OpenCorePkg> | BSD-3-Clause |
| OpenRuntime / OpenVariableRuntimeDxe / OpenHfsPlus / OpenCanopy / ResetNvramEntry | 随 OpenCore | 同上 | BSD-3-Clause |

## 必装 kext

| 组件 | 版本 | 上游 | 许可证 |
|---|---|---|---|
| Lilu | 1.7.3 | <https://github.com/acidanthera/Lilu> | BSD-3-Clause |
| VirtualSMC | 1.3.8 | <https://github.com/acidanthera/VirtualSMC> | BSD-3-Clause |
| SMCBatteryManager | 1.3.8 | 同上 | BSD-3-Clause |
| NVMeFix | 1.1.3 | <https://github.com/acidanthera/NVMeFix> | BSD-3-Clause |
| RestrictEvents | 1.1.6 | <https://github.com/acidanthera/RestrictEvents> | BSD-3-Clause |
| BrightnessKeys | 1.0.3 | <https://github.com/acidanthera/BrightnessKeys> | BSD-3-Clause |
| AppleMCEReporterDisabler | 1.2 | <https://github.com/acidanthera/AppleMCEReporterDisabler> | BSD-3-Clause |
| AMFIPass | 1.4.1 | <https://github.com/dhinakg/AMFIPass> | MIT |
| AmdTscSync | 2.0.0 | 上游见仓库说明 | 见上游 |
| USBToolBox | 1.2.0 | <https://github.com/USBToolBox/kext> | MIT |
| UTBMap | 1.1 | 由 USBToolBox 生成 | 同 USBToolBox |

## 显卡

| 组件 | 版本 | 上游 | 许可证 |
|---|---|---|---|
| RembrandtGPU | 1.0.0（bundle `com.rembrandtgpu.plugin`；release tag v0.1.1） | <https://github.com/FranciumOS-org/Radeonized> | **MIT**（代码）+ AMD 微码二进制许可 |
| RBAMDFramebuffer | 0.1.0（bundle `com.rembrandtgpu.fb`；安装到 `/Library/Extensions`） | <https://github.com/FranciumOS-org/Radeonized> | **MIT** |
| RembrandtGfx | 0.1.0（`com.hkvm.RembrandtGfx`） | <https://github.com/caoshiyuan0211-blip/winmax2-2022-6800u-hackintosh>（`src/RembrandtGfx`） | **GPL-2.0**（本分支 **Disabled**，仅作回退参考） |

- Radeonized 实际 UUID：`RembrandtGPU` = `E3A30962-A898-38B4-856D-402EE1FD0D50`；`RBAMDFramebuffer` = `31B2C56B-0FC6-3F8F-85C1-7DD4A2FBAFA1`。
- 上游 `README-INSTALL.md` 中的 UUID 是过期值；以 `dwarfdump --uuid` 和 aux KC 内实际 UUID 为准。
- Radeonized 的 MIT/AMD 许可文件在 `Radeonized/`；`RembrandtGPU.kext/Contents/Resources/LICENSE.amdgpu` 必须保留。
- 不包含任何板卡 VBIOS；VBIOS 由 ACPI `VFCT` 在启动时读取。

## 无线 / 蓝牙

| 组件 | 版本 | 上游 | 许可证 |
|---|---|---|---|
| AirportItlwm | 2.4.0（AWDL 构建 `2.4.0-awdl-8738ce5`） | <https://github.com/kevineduardo/ax210-airdrop-awdl-hackintosh>（基于 OpenIntelWireless/itlwm） | GPL-2.0 |
| IntelBluetoothFirmware | 2.5.3 | <https://github.com/OpenIntelWireless/IntelBluetoothFirmware> | **GPL-3.0** |
| IntelBTPatcher | 2.5.3 | 同上 | GPL-3.0 |
| BlueToolFixup | 2.7.3（advsets 构建） | <https://github.com/kevineduardo/ax210-airdrop-awdl-hackintosh>（基于 acidanthera/BrcmPatchRAM） | GPL-2.0 |

## 输入 / 音频

| 组件 | 版本 | 上游 | 许可证 |
|---|---|---|---|
| VoodooPS2Controller | 2.3.7 | <https://github.com/acidanthera/VoodooPS2> | BSD-3-Clause |
| VoodooInput（PS2 包内，启用） | 1.1.6 | <https://github.com/acidanthera/VoodooInput> | BSD-3-Clause |
| VoodooPS2Keyboard | 2.3.7 | 同上（VoodooPS2） | BSD-3-Clause |
| VoodooPS2Mouse / VoodooPS2Trackpad | 2.3.7 | 同上（**本配置关闭**） | BSD-3-Clause |
| VoodooI2C | 2.9.1 | <https://github.com/VoodooI2C/VoodooI2C> | **GPL-3.0** |
| VoodooI2CHID | 1.0 | 同上 | GPL-3.0 |
| VoodooGPIO | 1.1 | 随 VoodooI2C 依赖 | GPL-3.0 |
| VoodooI2CServices | 1.0 | 随 VoodooI2C 依赖 | GPL-3.0 |
| VoodooI2C 包内 VoodooInput（**本配置关闭**） | 随 VoodooI2C | 同上 | GPL-3.0 |
| VoodooHDA | 3.6.8 | 上游见 VoodooHDA 项目 | GPL-2.0 |
| AppleALC | 1.9.9（**本配置关闭**，仅随仓库保留） | <https://github.com/acidanthera/AppleALC> | BSD-3-Clause |

## 说明

- 本分支实际启用 **VoodooHDA**，AppleALC 仅作为备用保留并关闭。
- 触控板使用 VoodooI2C + VoodooI2CHID；`VoodooPS2Trackpad`/`VoodooPS2Mouse` 关闭；PS2 包内 VoodooInput 启用，VoodooI2C 包内 VoodooInput 随 live EFI 保留但关闭（避免重复）。
- `ATY,bin_image` VBIOS 不随仓库分发；Radeonized 从本机 ACPI `VFCT` 读取，不需要注入。
- AirDrop/AWDL 使用第三方 AWDL 分支的 AirportItlwm 与 BlueToolFixup advsets 构建，并需要对应 `-itlawdl*` / `-btlfxadvsets*` 启动参数；详见 [AIRDROP.md](AIRDROP.md)。升级 macOS 前先核对该分支支持的版本。
- 本分支只复测了显卡与 Wi-Fi；其余组件沿用 `main` 配置，未逐项复测。
