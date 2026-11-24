# 机械革命 无界14 2023（R7-7735H / Radeon 680M）Hackintosh — OpenCore EFI

**macOS Sequoia 15.8.3（24H241）· OpenCore 1.0.8 · SMBIOS `MacPro7,1` · 当前状态：日常基线可用**

本仓库是机械革命无界14 2023（AMD Ryzen 7 7735H + Radeon 680M）的 OpenCore EFI、安装记录与排障文档。2026-11-24 已按当前可工作的内置 ESP 重新同步，并重写了文档。

> **English summary:** OpenCore EFI and notes for the MECHREVO WUJIE 14 2023 (Ryzen 7 7735H / Radeon 680M). GPU acceleration works through RembrandtGfx 0.1.0 with the 680M spoofed as Navi 23 (`0x73FF`); the machine-specific VBIOS and SMBIOS serials are **not** included. Wi-Fi works after both cold and warm boots in the latest test; speakers and microphone only work after sleep/wake (same on Windows); camera works; external display and hardware video decode are unsupported. Touchpad works through VoodooI2C 2.9.1 with macOS native tap-to-click. Use your own SMBIOS and generate your own VBIOS from your VFCT.

---

## 硬件

| 部件 | 规格 |
|---|---|
| 机型 | 机械革命 无界14 2023（MECHREVO WUJIE 14 2023） |
| CPU | AMD Ryzen 7 7735H（Rembrandt，Zen3+，8C/16T） |
| 核显 | Radeon 680M（RDNA2；macOS 通过 RembrandtGfx 驱动） |
| 独显 | 无 |
| 内存 | 16 GB LPDDR5-6400 |
| 硬盘 | Intel 660p 512 GB + Fanxiang S690 1 TB（双 M.2 NVMe） |
| 网卡 | Intel AX210（Wi-Fi 6E / 蓝牙） |
| BIOS | AMI 2.22.1282 |
| 系统 | macOS Sequoia 15.8.3（24H241）；安装器记录为 15.8.2（24H232） |

## 当前状态

| 功能 | 状态 | 说明 |
|---|---|---|
| 显卡 / Metal | ✅ 可用 | RembrandtGfx 0.1.0；680M 伪装 Navi 23 `0x73FF`；报告 512 MB 显存（UMA/驱动报告值，实际共享内存 + GART） |
| 内屏 / 亮度 | ✅ 可用 | `SSDT-PNLF.aml` + BrightnessKeys 1.0.3 |
| Wi-Fi | ✅ 可用 | AX210 + AirportItlwm 2.4.0；冷启动/热启动均已实测可用 |
| 蓝牙 | ✅ 可用 | IntelBluetoothFirmware / IntelBTPatcher 2.5.3 + BlueToolFixup 2.7.2 |
| 音频 | ⚠️ 有条件 | VoodooHDA 3.6.8；**冷启动无声，睡眠唤醒后正常**；Windows 上同样存在，疑似引导阶段音频设备初始化问题 |
| 麦克风 | ⚠️ 有条件 | 可用；与音频相同，**冷启动后需睡眠唤醒才能识别到声音** |
| 摄像头 | ✅ 可用 | 2026-11-24 实测可用 |
| 触控板 | ✅ 可用 | VoodooI2C 2.9.1 + VoodooI2CHID；使用 macOS 原生轻点（不再使用自定义 VoodooInput） |
| 睡眠 / 唤醒 | ✅ 可用 | 正常唤醒 |
| USB | ✅ 可用 | USBToolBox + UTBMap；AMD xHCI interrupter 补丁 |
| NVMe | ✅ 可用 | NVMeFix 1.1.3；两块 NVMe 均识别 |
| 外接显示 | ❌ 不支持 | 当前 RembrandtGfx 方案未打通 |
| 硬件视频编解码 | ❌ 不支持 | 视频可播放不等于硬解可用 |
| 指纹 | ❓ 未验证 | — |
| iMessage / App Store | ❓ 需自行验证 | 公开版不含三码；换新三码后需重新登录 |

## 2026-11-24 本次更新

- EFI 从当前可工作的内置 ESP 同步，修正了旧仓库里 `device-id 0x737F`、VoodooI2C 关闭等过时内容。
- 触控板改为 **VoodooI2C 2.9.1 + VoodooI2CHID + 系统原生轻点**；自定义 VoodooInput（180 ms 双击窗口）在本机 Precision 触摸板上不稳定，已弃用（见 [docs/TOUCHPAD.md](docs/TOUCHPAD.md)）。
- 蓝牙、亮度、睡眠/唤醒按实测更新为可用；Wi-Fi 复测冷启动/热启动均可用；摄像头可用；麦克风可用但需睡眠唤醒；外接显示、硬解按实测写明限制。
- **公开仓库移除**：真实 SMBIOS 四码、`ATY,bin_image` VBIOS、OpenCore 日志、NVRAM/SysReport、旧 config 备份；历史已重写。
- 维护者本机已生成新 SMBIOS；公开配置里四码为空，必须自行生成。
- 旧 2026-11-21 快照保存在 `legacy-2026-11` 分支（仅文档/脚本，不含 config/VBIOS）。

## 仓库结构

```
EFI/
  BOOT/BOOTx64.efi
  OC/
    config.plist          # 四码为空、无 ATY,bin_image
    ACPI/                 # SSDT-CPUR / EC / EC-USBX / OCMARK / PLUG-ALT-16CPU / PNLF / SBUS-MCHC / XHC-OFF
    Drivers/              # OpenVariableRuntimeDxe / OpenRuntime / OpenHfsPlus / OpenCanopy / ResetNvramEntry
    Kexts/                # 当前启用与可选 kext（见 docs/COMPONENTS.md）
    Resources/            # OpenCanopy 主题
    Tools/OpenShell.efi
docs/
  INSTALL.md              # 安装、BIOS、三码与 VBIOS
  GPU.md                  # 680M / RembrandtGfx / VBIOS / 512 MB 显存说明
  TOUCHPAD.md             # VoodooI2C 与轻点方案
  COMPONENTS.md           # 组件版本、上游与许可证
  HISTORY.md              # 完整折腾记录
CHANGELOG.md
LICENSE                   # MIT（本仓库文档/配置）
THIRD_PARTY_NOTICES.md
scripts/
  sanitize-config.py      # 清空三码、移除 ATY,bin_image、清理悬空 kext 条目
```

## 快速开始

1. **生成自己的三码**（必需）：用 OpenCorePkg 的 `macserial` 或 GenSMBIOS 生成 `MacPro7,1` 的 `SystemSerialNumber`、`MLB`、`SystemUUID`、`ROM`，填入 `EFI/OC/config.plist → PlatformInfo/Generic`。**不要使用他人的三码。**
2. **生成自己的 VBIOS**：公开版 config 不含 `ATY,bin_image`。按 [docs/GPU.md](docs/GPU.md) 从本机 `VFCT` 生成并注入；直接套用他人的 VBIOS 可能黑屏。
3. **准备引导盘**：把 `EFI/` 放到 FAT32 U 盘或 ESP 根目录；做 Recovery 还需在 U 盘根目录放 `com.apple.recovery.boot/BaseSystem.dmg` + `BaseSystem.chunklist`。
4. **BIOS**：版本 2.22.1282；关闭 Secure Boot / Fast Boot，使用 UEFI 启动。
5. **首次进入系统**：触控板设置——打开“轻点来点按”，辅助点击选“双指轻点”，关闭“使用触控板来拖移”（详见 [docs/TOUCHPAD.md](docs/TOUCHPAD.md)）。
6. **音频 / 麦克风**：冷启动无声或麦克风未被识别时，睡眠再唤醒即可；这是当前已知限制。
7. **急救盘**：建议保留一个与内置 EFI 同版本的 U 盘 EFI，并保留旧版 `EFI.bak-*`。

## 关键配置

| 项 | 值 |
|---|---|
| boot-args | `-lilubetaall debug=0x100 keepsyms=1 -no_compat_check -no_restart amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 itlwm_he=1 ocax210seq1 -rmbxhciintr1 msgbuf=4194304 revpatch=cpuname,memtab revcpu=1` |
| Kernel Patch | 48 条（29 条启用）：AMD Vanilla + XHCI interrupter 1→0 |
| Kernel Quirks | `DisableIoMapper = True` |
| Kernel Block | `AppleSMCRTC`；`AppleUSBAudio` / `IOAudioFamily`（让 VoodooHDA 自带 family 接管） |
| ACPI（启用） | `SSDT-EC-USBX.aml`、`SSDT-PLUG-ALT-16CPU.aml`、`SSDT-PNLF.aml` |
| Drivers | `OpenVariableRuntimeDxe.efi`、`OpenRuntime.efi`、`OpenHfsPlus.efi`、`OpenCanopy.efi`、`ResetNvramEntry.efi` |
| 触控板 | VoodooI2C / VoodooI2CHID / VoodooGPIO / VoodooI2CServices 启用；VoodooPS2Trackpad / VoodooPS2Mouse 关闭 |
| 显卡 | RembrandtGfx 0.1.0；`device-id 0x73FF`；`model = AMD Radeon RX 6600`；无 `ATY,bin_image` |

完整版本表见 [docs/COMPONENTS.md](docs/COMPONENTS.md)。

## 已知问题

- **Wi-Fi 稳定性**：2026-11-24 复测热启动正常；若遇到异常，断电冷启动可恢复。
- **音频 / 麦克风冷启动异常**：扬声器冷启动无声、麦克风冷启动后无法识别；睡眠唤醒后恢复。Windows 上同样存在，疑似 OpenCore 引导阶段的音频设备初始化问题，当前未修复。
- **外接显示 / 硬件视频编解码**：当前 RembrandtGfx 方案不支持。
- **系统更新**：升级 macOS 前先备份 EFI；RembrandtGfx 与 VoodooI2C 可能需要重新验证。
- **公开版不含三码与 VBIOS**：这是有意为之，避免泄露与误用。

## 安全与合规

- 仓库历史已在 2026-11-24 重写，移除了旧的 `EFI/OC/config.plist` 与 `docs/config-backups/`；但 fork、缓存和搜索引擎可能仍保留旧对象。维护者已更换新 SMBIOS，**旧三码请视为已泄露**。
- 公开树不包含真实序列号、`ATY,bin_image`、OpenCore 日志、NVRAM、SysReport。
- 本仓库原创文档与配置使用 MIT；第三方 kext 按各自许可证分发，见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 参考与致谢

- 显卡方案与 RembrandtGfx：<https://github.com/caoshiyuan0211-blip/winmax2-2022-6800u-hackintosh>（GPL-2.0）
- 触控板配置参考：<https://github.com/PiyushAdy/Thinkbook_G7_7735HS_680M_Hackintosh>
- [Acidanthera](https://github.com/acidanthera)：OpenCore、Lilu、VirtualSMC、NVMeFix、RestrictEvents、BrightnessKeys、AppleALC、VoodooPS2
- [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C)：VoodooI2C / VoodooI2CHID
- [OpenIntelWireless](https://github.com/OpenIntelWireless)：AirportItlwm、IntelBluetoothFirmware
- [dhinakg/AMFIPass](https://github.com/dhinakg/AMFIPass)、[USBToolBox](https://github.com/USBToolBox/kext)
- Dortania OpenCore Install Guide（AMD 配置）

## 免责声明

黑苹果属于非官方改装，Apple 不提供支持。使用本仓库造成的系统不稳定、数据丢失、硬件问题或 Apple 服务限制，由使用者自行承担。安装前请完整备份 EFI 与数据，并遵守 macOS 软件许可协议。
