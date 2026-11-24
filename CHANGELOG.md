# Changelog

## 2026-11-24

### 追加实测

- Wi-Fi：热启动复测正常（不再要求冷启动）。
- 摄像头：可用。
- 麦克风：可用，但与扬声器相同，冷启动后需睡眠唤醒才能识别到声音。

### EFI

- 以当前可工作的内置 ESP 为基准重新同步 `EFI/`。
- GPU：`device-id` 修正为 `0x73FF`（旧仓库为 `0x737F`）；保留 `model = AMD Radeon RX 6600`、`RembrandtGfx 0.1.0`；**公开版移除 `ATY,bin_image`**。
- 触控板：启用 VoodooI2C 2.9.1、VoodooI2CHID、VoodooGPIO、VoodooI2CServices；关闭 VoodooPS2Trackpad / VoodooPS2Mouse；VoodooInput 使用 PS2 包内上游 **1.1.6**。
- 删除未使用的自定义 `VoodooI2C .../VoodooInput.kext`（1.1.7）。
- 清理指向不存在文件的 `Kernel → Add` 条目（itlwm、NootedRed、WhateverGreen、RDNA3Driver 等）。
- `.gitattributes` / `.gitignore` 去除 BOM，忽略日志、NVRAM、SysReport、config 备份等。
- `scripts/sanitize-config.py` 增加：移除 `ATY,bin_image`、清理悬空 kext 条目、校验三码为空。

### 文档

- 重写 README：硬件、状态矩阵、已知问题、安装步骤、安全说明。
- 新增 `docs/INSTALL.md`、`docs/GPU.md`、`docs/TOUCHPAD.md`、`docs/COMPONENTS.md`、`docs/HISTORY.md`。
- 新增 `LICENSE`（MIT）与 `THIRD_PARTY_NOTICES.md`。

### 安全

- 重写 `main` 历史，移除旧 `EFI/OC/config.plist` 与 `docs/config-backups/` 中的真实 SMBIOS 数据。
- 维护者本机已生成新 SMBIOS；公开配置四码为空。
- 旧 2026-11-21 快照移至 `legacy-2026-11` 分支（仅文档/脚本，无 config/VBIOS）。
- 注意：force push 无法清除 fork/缓存/搜索引擎索引，旧三码应视为已泄露。

## 2026-11-21（历史）

- AX210 + AirportItlwm 2.4.0 Sequoia 日常基线；RembrandtGfx 启用。
- 旧快照见 `legacy-2026-11`。

## 2026-10-30（历史）

- 初始仓库：OpenCore 1.0.8 EFI、NVMe `nvme=-1` 解法、折腾记录。
