# 显卡：Radeon 680M / RembrandtGfx

## 结论

- 680M 没有独立显存，是 UMA 核显；macOS 报告 **512 MB** 是驱动读取的 UMA carve-out/报告值，不是独立显存容量。实际显存池来自共享系统内存 + GART。
- macOS 通过 **RembrandtGfx 0.1.0**（`com.hkvm.RembrandtGfx`，Lilu 插件）让 Apple 的 `AMDRadeonX6000`（Navi 2x）驱动栈接管 Rembrandt iGPU。
- 设备伪装：`device-id = 0x73FF`（Navi 23 / RX 6600）、`model = AMD Radeon RX 6600`，并注入本机生成的 `ATY,bin_image` VBIOS。
- 当前限制：**外接显示不支持**，**硬件视频编解码不支持**。

## 来源与许可证

该方案来自 GPD Win Max 2 6800U 项目：

- <https://github.com/caoshiyuan0211-blip/winmax2-2022-6800u-hackintosh>（GPL-2.0）

其中 `src/RembrandtGfx` 就是本仓库 `EFI/OC/Kexts/RembrandtGfx.kext` 的上游源码；`efi/config.plist.example` 的 GPU 配置为：

```text
PciRoot(0x0)/Pci(0x8,0x1)/Pci(0x0,0x0)
  device-id              ff730000   (0x73FF)
  model                  AMD Radeon RX 6600
  AAPL,iokit-ignore-ndrv 01000000
  CFG_NO_BOOT_PWDN       0100000000000000
  CFG_USE_AGDC           0000000000000000
  ATY,bin_image          <本机 VFCT 生成的 VBIOS>
```

本仓库公开版**不含** `ATY,bin_image`，也不分发 VBIOS 二进制。

## VBIOS 为什么不能通用

`ATY,bin_image` 是从本机 ACPI `VFCT` 表提取、再把 PCI device id 改成 `0x73FF` 的 Rembrandt VBIOS。不同机型/面板/显存配置的 VBIOS 不同，直接套用别人的镜像可能黑屏或显示异常。

### 生成步骤（在上游项目环境/Linux 下）

1. 复制本机 VFCT：

   ```sh
   cp /sys/firmware/acpi/tables/VFCT .
   ```

2. 从 VFCT 提取 ROM：

   ```sh
   python3 scripts/vfct-rom.py VFCT
   ```

3. 改成 Navi 23 device id 并修正 ATOM 校验和：

   ```sh
   python3 scripts/augment-rom.py roms/680m-73ff.rom roms/680m-73ff-aug.rom
   ```

4. 把生成的二进制作为 **data** 写入 `EFI/OC/config.plist` 的 GPU `DeviceProperties`：

   ```text
   PciRoot(0x0)/Pci(0x8,0x1)/Pci(0x0,0x0) → ATY,bin_image = <rom bytes>
   ```

   注意：脚本与字段格式以对应上游仓库版本为准。

## 512 MB 显存说明

| 项目 | 含义 |
|---|---|
| `VRAM,totalMB = 512` | Apple 驱动读取的报告值/UMA carve-out，不是物理独立显存 |
| 系统内存 | 16 GB 共享池 |
| GART | 驱动按需把系统内存映射给 GPU（本机窗口约 6 GB） |

所以看到 512 MB 不需要“扩显存”操作；实际可用内存取决于共享内存与 GART。日常桌面/Metal 已可用，但不要按独显的显存预期使用。

## 已验证 / 未验证

- ✅ Metal 计算、桌面合成、内屏显示
- ✅ 亮度调节（BrightnessKeys + SSDT-PNLF）
- ❌ 外接显示（HDMI/DP/USB-C）
- ❌ 硬件视频编解码（H.264/HEVC/AV1/VP9 硬解）
- ❓ 3D 游戏/重负载长期稳定性

## 相关启动参数

```text
-agdpmod 相关参数未使用
-rmbxhciintr1   保留 xHCI interrupter 1 的调试开关（USB 相关，见 RembrandtGfx 源码）
```

RembrandtGfx 的其他 `-rmb*` 开关见上游 `src/RembrandtGfx/*.cpp` 中的 `checkKernelArgument` 列表。

## 更新显卡驱动时

1. 备份当前 EFI。
2. 用上游新版源码重新构建 `RembrandtGfx.kext`（需要 cctools-port/macOS 内核符号列表，见上游 README）。
3. 先只替换 kext，保留现有 `ATY,bin_image` 与 DeviceProperties，确认能启动。
4. 再考虑调整 boot-args；每次只改一项。
