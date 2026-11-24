# Hackintosh — 机械革命 无界14 2023（R7-7735H / Radeon 680M）

**OpenCore 1.0.8 引导配置 · 完整折腾记录 · 当前状态：macOS Sequoia 日常基线可用；触控板、蓝牙、亮度调节仍未完成**

---

## 硬件

| 部件 | 规格 |
|---|---|
| CPU | AMD R7-7735H（Rembrandt，Zen3+） |
| 核显 | **Radeon 680M（RDNA2，macOS 无驱动）** |
| 独显 | 无 |
| 内存 | 16GB LPDDR5-6400 |
| 硬盘 | Intel 660p 512G + Fanxiang S690 1TB（双 M.2 NVMe） |
| 网卡 | Intel AX210（Wi-Fi 6E，当前通过 `AirportItlwm 2.4.0 Sequoia`） |
| BIOS | AMI 2.15（无 NVMe 禁用项、无 PCIe 速度选项） |

## 成果进展（截至 2026-11-21）

| 项目 | 状态 | 说明 |
|---|---|---|
| **AppleAPIC / CPU 枚举** | ✅ 已通过 | `SSDT-PLUG-ALT-16CPU.aml` 为 16 个 ACPI0007 CPU 补充 macOS 可用的 Processor 对象 |
| **PCI / 设备树** | ✅ 已通过 | `clean-lab / occlean1` 仅保留标准 AMD 补丁 0–24，不再需要全局 bridge/device 返回补丁 |
| **Kernel / 存储栈** | ✅ 已通过 | 已加载 USB、SCSI、IOStorage、APFSMedia，并进入根卷查找阶段 |
| **完整 Recovery** | ✅ 已完成 | 修复跨版本 Recovery 混装，BaseSystem 与匹配内核集合通过校验 |
| **Recovery 启动** | ✅ 已通过 | 成功进入 macOS Sequoia 恢复主菜单和安装器 |
| **USB 输入** | ✅ 已修复 | USBToolBox 端口映射 + AppleUSBXHCI interrupter 1→0，鼠标移动已可用 |
| **内部 NVMe** | ✅ 已识别 | 移除 `nvme=-1` 后，Fanxiang S690 1TB 与 Intel 512GB 均显示在磁盘工具 |
| **Wi-Fi** | ✅ 已可用 | `AirportItlwm 2.4.0 Sequoia + Lilu 1.7.3 + AMFIPass 1.4.1`，不再依赖 HeliPort |
| **macOS 安装** | ✅ 已完成 | 使用完整 `15.8.2 / 24H232` 离线安装器安装到 Fanxiang APFS 分区 |
| **首次进入系统** | ✅ 已通过 | 安装后能够启动并进入 macOS Sequoia 桌面 |
| **GPU / WindowServer** | ✅ 当前可用 | `RembrandtGfx.kext` 已启用；日常界面可进入，细分性能与 Metal 功能仍待记录 |
| **触控板** | ❌ 未完成 | VoodooPS2 已启用，但触控板仍需继续调试 |
| **蓝牙** | ❌ 未完成 | Intel Bluetooth 组件尚未形成稳定可用方案 |
| **亮度调节** | ❌ 未完成 | 内屏亮度快捷键与原生亮度链路仍未完成 |
| **NVMe 历史解法** | ✅ 已归档 | 旧配置曾用 `nvme=-1` 解决 IONVMeFamily panic |
| 三码 | ⚠️ 已清空 | 发布版不含序列号，**使用前必须自行生成**（见下） |

---

## 使用方法

> ⚠️ **重要：发布版 config.plist 已清空三码（SystemSerialNumber / MLB / SystemUUID / ROM），不生成三码无法启动，且不要使用他人的三码。**

> 🔐 **历史安全说明：** 早期公开提交中的部分 plist 曾包含真实 SMBIOS 标识。当前工作树已统一清空全部 tracked plist 的四项字段，但普通 Git 提交无法删除旧提交历史。建议为本机重新生成新的 MacPro7,1 三码；如需彻底清除历史，需要对仓库执行一次经过备份的 history rewrite。

1. **生成自己的三码**（MacPro7,1）：
   - 下载 [macserial](https://github.com/acidanthera/OpenCorePkg/releases)（OpenCorePkg 内 Utilities/macserial），执行：
     ```
     macserial -s -n 20 -m MacPro7,1
     ```
   - 任选一组填入 `EFI/OC/config.plist` → `PlatformInfo/Generic`：
     - `SystemSerialNumber`
     - `MLB`
     - `SystemUUID`（可留空让 OpenCore 自动生成）
2. **准备 EFI 分区**：将本仓库 `EFI` 目录复制到 FAT32 U 盘（或 ESP 分区）根目录，卷标随意。
3. **放入完整 macOS 恢复镜像**：在 U 盘根目录建 `com.apple.recovery.boot/`，必须放入 `BaseSystem.dmg` + `BaseSystem.chunklist`。只有 `boot.efi` 和 `BootKernelExtensions.kc` 会进入 `Still waiting for root device.`。
4. **BIOS 设置**：关闭 Secure Boot / Fast Boot，开启 UEFI USB 引导，从 U 盘启动 OpenCore。
5. 选择已安装 macOS 的系统卷进入系统。当前配置已完成启动、Wi-Fi、USB、内部 NVMe 和日常使用验证。

## 关键配置

| 项 | 值 | 作用 |
|---|---|---|
| boot-args | `-lilubetaall debug=0x100 keepsyms=1 -no_compat_check -no_restart amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 itlwm_he=1 ocax210seq1 -rmbxhciintr1 msgbuf=4194304` | 当前日常可用基线 |
| Kernel/Patch | 标准 AMD 补丁 + 6 个 XHCI interrupter 1→0 | 修复 AMD xHCI 连续输入事件延迟 |
| Kernel/Block | `IONVMeFamily` 不屏蔽 | 允许内部 NVMe 发布 block storage device |
| Kernel/Quirks | `DisableIoMapper=True` | 必需（AMD 平台） |
| 启用 kext | Lilu / RembrandtGfx / AMFIPass / AirportItlwm / AppleMCEReporterDisabler / VirtualSMC / SMCBatteryManager / NVMeFix / AmdTscSync / VoodooPS2Controller 及插件 / USBToolBox / UTBMap | 当前工作树已归档所需二进制 |
| 启用 ACPI | SSDT-EC-USBX / SSDT-PLUG-ALT-16CPU | 其余 XHC/APSP/OCMARK 诊断项已关闭 |
| Drivers | OpenVariableRuntimeDxe（LoadEarly）/ OpenRuntime / OpenHfsPlus / OpenCanopy / ResetNvramEntry | 当前工作树已归档 |
| DeviceProperties | 无 GPU 伪装 | 当前保留原始 `1002:1681` 设备身份，避免污染后续原生 X6000 调试 |

## 测试记录（完整版见 `docs/折腾记录.md`）

### 显卡（7 种配置全部卡 DSMOS 后显示初始化）
`-x`（恢复环境不支持）→ `agdpmod=pikera radpg=15` → 删伪装 → 最小化 kext（过 SMCRTC）→ 禁 AppleSMCRTC（过到 DSMOS）→ `-igfxvesa`（无效）→ 伪装+最小化（卡 DSMOS）

### NVMe（4 种配置全 panic → nvme=-1 解决）
双盘（panic）→ 单盘 660p 换槽（panic）→ NVMeFix 重开（panic）→ 换槽+只插 Fanxiang（panic）→ **`nvme=-1`（双盘全过 ✅）**

### 2026-11-10 白苹果里程碑
verbose console relocation 卡死 → 清理 XHC/APSP ACPI 诊断拓扑 → 精确定位 AMD bridge `0:8:1` PFM 写入 → 跳过 bridge configuration → 完成 PCI device tree → 切换 `ui-lab` 非 verbose 启动 → **白苹果和启动进度条出现 ✅**

### 2026-11-12 引导链里程碑
发现 DSDT 只有 16 个 `ACPI0007` CPU Device → 增加 `SSDT-PLUG-ALT-16CPU.aml` → 通过 `AppleAPIC` → 关闭 25 号以后的实验性内核补丁 → 通过 PCI、USB、SCSI、IOStorage 和 APFSMedia → 最终停在 `Still waiting for root device.`。这证明引导链已经工作，但当前 USB 缺少完整 `BaseSystem.dmg`，且没有可挂载的 APFS 系统卷。

### 2026-11-13 Recovery 与 USB 输入里程碑
补齐 `BaseSystem.dmg` → 进入 Sequoia Recovery → USBToolBox 映射全部 16 个端口 → 发现 AMD XHCI 仅有一个实际 MSI，而 macOS 普通 TRB 指向 interrupter 1 → 将 6 类 TRB 的 interrupter target 改成 0 → 鼠标连续移动从严重积压恢复到可用。

### 2026-11-14 内部 NVMe 里程碑
磁盘工具仅显示内存镜像 → `kextstat`/`ioreg` 确认 IONVMeFamily 已加载且两个控制器 active → 未发布 block storage device → 移除 `nvme=-1` → 两块内部 NVMe 均被磁盘工具识别。

### 2026-11-20 macOS 安装与首次进入系统

- 确认原 Recovery 存在内核、boot.efi 和 BaseSystem 跨版本混装，重建为匹配的 15.6.1 Recovery。
- AX210 在 Recovery 中改用 `itlwm`，并由 HeliPort 连接 Wi-Fi；`AirportItlwm` 会阻塞进入安装器。
- 使用完整 `InstallAssistant.pkg` 制作离线数据，绕过 Recovery 的 `pkgutil`/`xar` 大文件缺陷。
- `SharedSupport.dmg` 通过精确偏移和 SHA‑256 校验恢复，随后完成 macOS 安装。
- 安装后可正常重启并进入 macOS Sequoia 桌面。

## 结论

`ocax210seq1` 是当前的日常可用基线。系统启动、AX210 Wi-Fi、USB、内部 NVMe、电池信息与基础输入栈已经可以工作；RembrandtGfx 已启用并允许进入当前桌面环境。

当前仍未完成的项目是触控板、蓝牙和亮度调节。仓库保留这些组件的现有文件和阶段性配置，但不会把未验证方案描述为已解决。

本仓库为**全量方案存档**：包含 OpenCore、Recovery、USB/xHCI、NVMe、AX210、离线安装和已进入系统后的完整阶段记录。`docs/config-backups/` 保存分阶段配置，当前状态见 `config-working-macos-sequoia-2026-11-21.plist`。

## 参考

- [Dortania OpenCore 安装指南（AMD 配置）](https://deepwiki.com/dortania/OpenCore-Install-Guide/4.4-amd-configurations)
- [NVMeFix（acidanthera）](https://github.com/acidanthera/NVMeFix)
- [PC711Probe —— 特定 NVMe 的 Lilu 修复插件先例](https://www.insanelymac.com/forum/topic/363054-i-fixed-the-sk-hynix-pc711-kernel-panic-on-macos-12%E2%80%9315-%E2%80%94-pc711probe-is-now-public/)
- [AMD OS X：IONVMeFamily panic 讨论](https://forum.amd-osx.com/threads/cpu-panic-when-boot-with-ionvmefamily-iostoragefamily.4365/)
