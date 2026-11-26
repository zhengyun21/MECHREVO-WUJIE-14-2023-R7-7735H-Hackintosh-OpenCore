# 显卡：AMD Radeon 680M / Radeonized

## 结论

本分支（`radeonized-680m`）使用 **[Radeonized](https://github.com/FranciumOS-org/Radeonized) v0.1.1** 驱动 Radeon 680M：

- 显卡以真实 **`1002:1681`** 出现，**不伪装**成 Navi 23 / RX 6600。
- **不需要 `ATY,bin_image`**：`RembrandtGPU` 插件启动时从本机 ACPI `VFCT` 表读取 VBIOS；公共仓库不含任何板卡 VBIOS。
- `RBAMDFramebuffer.kext` 自写 IOFramebuffer，接管内屏、亮度与刷新率；装到 `/Library/Extensions` 并重建 aux KC。
- 680M 没有独立显存，是 UMA 核显；macOS 报告 **512 MB** 是 UMA carve-out/报告值，实际显存池来自共享内存 + GART。
- 本分支实测：**Metal 3**、**2560×1600 @120Hz**、HiDPI **1280×800**、**Wi-Fi 正常**、**睡眠失效**；其他功能未复测。**本机主观对比：流畅度低于 `main`（RembrandtGfx），卡顿/掉帧更明显。**

## 组件与 UUID

| 组件 | 作用 | 实际 Mach-O UUID |
|---|---|---|
| `RembrandtGPU.kext` | Lilu 插件，接管 Apple `AMDRadeonX6000` 栈，读 ACPI VFCT，发布 VBIOS | `E3A30962-A898-38B4-856D-402EE1FD0D50` |
| `RBAMDFramebuffer.kext` | IOFramebuffer，内屏/亮度/刷新率 | `31B2C56B-0FC6-3F8F-85C1-7DD4A2FBAFA1` |

`RembrandtGPU.kext` 位于 `EFI/OC/Kexts/`，排在 `Lilu.kext` 之后；`RBAMDFramebuffer.kext` 位于 `Radeonized/`，安装到 `/Library/Extensions`。

> 上游 `README-INSTALL.md` 中的 `52930D70…` / `2527A89E…` 是过期值；以实际二进制 UUID 为准。

## 安装

1. 使用本仓库 `EFI/`（`config.plist` 已按公开规则清空四码、无 `ATY,bin_image`）。
2. 生成自己的 SMBIOS（见 [INSTALL.md](INSTALL.md)）。
3. 安装 framebuffer：
   ```sh
   sudo ./scripts/install-radeonized-framebuffer.sh
   ```
   脚本会 dry-run、备份、写入并回读校验 UUID。手动步骤见 [INSTALL.md](INSTALL.md)。
4. 重启后验证：
   ```sh
   system_profiler SPDisplaysDataType
   ioreg -rl -c RembrandtGPUPeer | tr ',' '\n' | grep -E '"(armed|arm_why|vbios_src|acpivbios|fbaccel_on)"='
   ```
   预期 `AMD Radeon 680M`、`Metal 3`、`512 MB`；`armed=1`、`arm_why=0`、`vbios_src=3`、`acpivbios=0`。

## 512 MB 显存说明

| 项目 | 含义 |
|---|---|
| `VRAM,totalMB = 512` | Apple 驱动读取的报告值/UMA carve-out，不是物理独立显存 |
| 系统内存 | 16 GB 共享池 |
| GART | 驱动按需映射系统内存给 GPU（本机约 6 GB 窗口） |

本机 BIOS 没有可用的 UMA Frame Buffer Size 调整项，所以 512 MB 是当前上限。显存 heap 紧张时会退到 GART，重负载可能出现分配失败/卡顿；日常桌面与 Metal 可用，但本机流畅度仍低于 `main`，日常使用建议 `main`。

## 已验证 / 未验证

- ✅ 显卡 / Metal 3 / 内屏 2560×1600 @120Hz / HiDPI 1280×800（但流畅度低于 main，见下）
- ✅ Wi-Fi（AX210 + AirportItlwm）
- ❌ 睡眠 / 唤醒（当前 Radeonized 方案失效）
- ❓ 亮度、AirDrop、蓝牙、音频/麦克风、摄像头、触控板、USB、NVMe：未在本分支复测
- ❓ 外接显示：Radeonized 上游当前未打通 USB-C DP
- ❓ 硬件视频编解码：上游未完成
- ❓ 重负载/游戏长期稳定性

## 相关启动参数

本分支 boot-args 中的 Radeonized 参数：

```text
-rbgpufbnative
-rbgpufbhidpi
-rbgpuvbl
-rbgpuvblpump
-rbgpufbvbl
rbgpuvblhz=119807Hz
-rbgpufbaux
```

- `rbgpuvblhz=119807Hz` 是本机 120Hz 面板的 vblank 计时；换面板/刷新率时需要重新测量。
- `-rbgpufbhidpi` 提供 1280×800 HiDPI。
- `-rbgpufbaux` 武装 AUX/EDID 路径（只读；不触发时不发事务）。
- 上游 `README-INSTALL.md` 与源码里有更多 token；不要一次改多项。

## 已知表现

- 系统信息/显示器设置可能显示物理尺寸 **42"**（fbkext 未把 EDID 交给 IODisplay）；不影响实际 2560×1600/120Hz。本仓库不收录修改该显示的 override。
- 上游标注偶发 stall；本机实测流畅度低于 `main`（RembrandtGfx），卡顿/掉帧更明显，不限于重负载。
- 可能原因：512 MB UMA carve-out/VRAM heap 紧张与 GART 回退；上游偶发 stall（work submitted never retires）。
- 未完成 60Hz + `rbgpuvblhz=60000Hz` 等进一步对比；不要把未验证的调优当成结论。
- `RBAMDFramebuffer` 在 Recovery/安装器中不接管，保持 stock 路径。

## 回退到 main（RembrandtGfx）

如果追求日常流畅度，建议直接用 `main`（RembrandtGfx）：本机 Radeonized 流畅度更低、卡顿更多；仅需实验/参考时使用本分支：

- `main` 使用 RembrandtGfx 0.1.0 + `device-id 0x73FF` 伪装 + 本机生成的 `ATY,bin_image`。
- 本分支的 `EFI/OC/Kexts/RembrandtGfx.kext` 仍保留但 **Disabled**，仅作参考；回退时建议直接使用 `main` 的完整 EFI，避免混用两套显卡配置。
- 切换方案前备份 EFI 和 `/Library/KernelCollections/AuxiliaryKernelExtensions.kc`。

## 许可证

- Radeonized 代码：MIT（`Radeonized/LICENSE`，`Copyright (c) 2026 RembrandtGPU contributors`）
- 内嵌 AMD 微码：`Radeonized/LICENSE.amdgpu`（仅二进制再分发；禁止反向工程/反编译/反汇编；必须随附版权/许可/免责声明）
- 上游：<https://github.com/FranciumOS-org/Radeonized>
- 本仓库不包含任何板卡 VBIOS。
