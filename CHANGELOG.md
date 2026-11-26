# Changelog

## 2026-11-26

### Radeonized 分支（`radeonized-680m`）

- 新增实验分支：显卡从 RembrandtGfx 切换为 [Radeonized](https://github.com/FranciumOS-org/Radeonized) v0.1.1。
- 680M 以原生 `1002:1681` 出现；删除 `device-id 0x73FF` / `model` / `ATY,bin_image` / `CFG_*`，不再伪装 Navi 23，不需要 VBIOS 注入。
- `RembrandtGPU.kext` 排在 `Lilu.kext` 之后并启用；`RembrandtGfx.kext` 保留但 Disabled，作为回退。
- 新增 `Radeonized/RBAMDFramebuffer.kext`、MIT/AMD 许可证、`Radeonized/README.md` 与 `scripts/install-radeonized-framebuffer.sh`（dry-run、备份、aux KC UUID 回读）。
- 实测：Metal 3、2560×1600 @120Hz、HiDPI 1280×800、512 MB UMA；**Wi-Fi 正常、睡眠失效、其他功能未复测**。
- OpenCore `Resolution=2560x1600@32`（保持 fb 几何），`UIScale=2`（引导图标放大）。
- 新增实测截图 `docs/images/radeonized-680m.png`。

### 安全

- 移除 main 上遗留的两个 `config.before-*.plist` 备份（含真实 SMBIOS/ROM 与 `ATY,bin_image`）。
- `.gitignore` 增加 `config.before-*.plist`。
- 说明：main 历史/fork/缓存仍可能保留旧对象，旧三码请视为已泄露；彻底清理 main 历史需单独重写/force-push。

### 文档

- README 定向更新为 Radeonized 实验分支，明确 main 仍是 RembrandtGfx 稳定基线。
- 更新 `docs/GPU.md`、`docs/INSTALL.md`、`docs/COMPONENTS.md`、`THIRD_PARTY_NOTICES.md`。
- 记录睡眠失效、其他功能未复测、512 MB 显存与 42" 物理尺寸显示限制。

## 2026-11-24

### 追加实测

- Wi-Fi：热启动复测正常（不再要求冷启动）。
- 摄像头：可用。
- 麦克风：可用，但与扬声器相同，冷启动后需睡眠唤醒才能识别到声音。

### AirDrop / AWDL

- `AirportItlwm.kext` 替换为 AWDL 构建（`2.4.0-awdl-8738ce5`），`BlueToolFixup.kext` 替换为 2.7.3 advsets 版。
- `boot-args` 增加 `-itlawdl*`、`-btlfxadvsets*`，并用 `-itlawdlanybuild` / `-btlfxadvsetsany` 适配未在测试列表中的 15.8.3。
- 实测 `awdl0` UP、`AirDrop: Supported`；新增 `docs/AIRDROP.md`。
- 来源：<https://github.com/kevineduardo/ax210-airdrop-awdl-hackintosh>（实验性 beta）。

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
