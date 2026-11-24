# AirDrop / AWDL（Intel AX210）

## 状态

- 当前：**AirDrop 可用（实验性 beta）**
- 硬件：Intel AX210；系统：macOS Sequoia 15.8.3（24H241）
- 验证依据：`awdl0` 已 UP，`system_profiler SPAirPortDataType` 显示 `AirDrop: Supported`，固件字符串为 `itlwm: 2.4.0-awdl-8738ce5`；实机 AirDrop 可用

## 来源与许可证

方案来自：

- <https://github.com/kevineduardo/ax210-airdrop-awdl-hackintosh>

它是 [OpenIntelWireless/itlwm](https://github.com/OpenIntelWireless/itlwm) 中 AirportItlwm 的 AWDL 分支，kext 为 **GPL-2.0**，工具/文档为 MIT。请保留其上游声明；不要把该分支的 kext 当作官方 AirportItlwm 发布。

## 相对普通 AirportItlwm 的改动

本仓库 EFI 与之前相比只有三处变化：

1. `AirportItlwm.kext` 替换为 AWDL 版（构建字符串 `2.4.0-awdl-8738ce5`）
2. `BlueToolFixup.kext` 替换为 **2.7.3 advsets** 版（上游普通 BlueToolFixup + BLE advertising sets 表，让 iPhone 能在 AirDrop 列表里发现 Mac）
3. `boot-args` 增加 AWDL/advsets 开关

没有新增其他 kext，也没有改 GPU/触控板配置。

## 启动参数

本机当前使用的完整附加参数：

```text
-itlawdl -itlawdlaw -itlawdllisten -itlawdlp2p -itlawdltx -itlawdldata \
-itlawdlpromisc -itlawdltxpump itlawdllead=30000 -itlawdlfollow \
-btlfxadvsets -itlawdlanybuild -btlfxadvsetsany
```

说明：

- 前 10 个是上游 Sequoia 测试集（见其 `docs/installation.md` / `docs/boot-args.md`）
- `-itlawdlanybuild` / `-btlfxadvsetsany`：本机 macOS 15.8.3 不在上游声明的测试范围（15.8.1）内，用来跳过构建版本检查；升级系统后若上游已支持对应版本，可尝试去掉
- `-btlfxadvsets` 必须配合 advsets 版 BlueToolFixup
- 不要把 `itlwm.kext` 与其他 AirportItlwm 同时启用

## 验证

```sh
# 1. awdl0 是否存在且 UP
ifconfig awdl0

# 2. Wi-Fi 信息里是否显示 AirDrop: Supported
system_profiler SPAirPortDataType | grep -A2 -B2 AirDrop

# 3. AWDL 固件/驱动
system_profiler SPAirPortDataType | grep -i 'Firmware Version'

# 4. advsets 是否应用（需要重启后看）
log show --last boot --predicate 'eventMessage CONTAINS "[advsets]"' | tail
```

AirDrop 实测：iPhone/Mac 互相发现并传输；若 Mac 偶尔从 iPhone 的 AirDrop 列表消失，可尝试 `killall sharingd`。

## 要求与限制

- macOS Sequoia **15.2 或更高**；本机 15.8.3 通过 `*anybuild` 参数工作
- 仅 AX210 经过测试；同系列 AX200/AX211/AX411 等 iwx 卡理论上可尝试，但未验证
- 实验性 beta：发现偶发失败、Mac → iPhone 速度可能较慢；上游记录另有 BLE/AWDL 细节
- 升级 macOS 前先确认上游分支支持新版本，并保留已知可用的 EFI/USB 急救盘
- Tahoe（macOS 26）需要额外 `-itlawdlhometx -ibtcompatbeta`，并把 `Kernel → Quirks → PowerTimeoutKernelPanic` 设为 `false`；本机 Sequoia 未改该 quirk

## 回滚

1. 从 `boot-args` 去掉所有 `-itlawdl*`、`-btlfxadvsets*`（含 `*any` 版本）
2. 换回之前的 `AirportItlwm.kext` 与 `BlueToolFixup.kext`
3. 重启；没有 `-itlawdl` 时 AWDL 版 AirportItlwm 会按普通 AirportItlwm 工作
4. 若出现 panic，优先恢复旧 EFI（U 盘 `EFI.bak-*` / 桌面备份）

## 参考

- 上游安装说明：<https://github.com/kevineduardo/ax210-airdrop-awdl-hackintosh/blob/main/docs/installation.md>
- 启动参数详解：<https://github.com/kevineduardo/ax210-airdrop-awdl-hackintosh/blob/main/docs/boot-args.md>
- AWDL 工作原理：<https://github.com/kevineduardo/ax210-airdrop-awdl-hackintosh/blob/main/docs/how-awdl-works.md>
