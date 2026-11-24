# 安装与首次启动

## 前置条件

- 机械革命无界14 2023（R7-7735H / 680M），BIOS **2.22.1282**
- 一个 FAT32 U 盘（引导）和至少 16 GB 的安装介质/分区
- 能运行 `macserial` 或 GenSMBIOS 的环境
- 本机 ACPI `VFCT`（用于生成自己的 VBIOS，见 [GPU.md](GPU.md)）

## 1. 生成自己的 SMBIOS（必需）

公开版 `EFI/OC/config.plist` 的四个字段为空：

- `PlatformInfo/Generic/SystemSerialNumber`
- `PlatformInfo/Generic/MLB`
- `PlatformInfo/Generic/SystemUUID`
- `PlatformInfo/Generic/ROM`

用 OpenCorePkg 的 `macserial`（或 GenSMBIOS）生成 `MacPro7,1`：

```sh
macserial -m MacPro7,1 -n 20
# 或
macserial -s -n 20 -m MacPro7,1
```

任选一组填入上述字段；`ROM` 建议用本机有线/无线网卡 MAC 的 6 字节。**不要使用仓库作者或他人的三码。**

## 2. 生成并注入自己的 VBIOS

公开版**不含** `ATY,bin_image`。按 [GPU.md](GPU.md) 从本机 `VFCT` 生成，并写入 GPU 的 `DeviceProperties`。没有这一步，显卡不会以当前方式工作。

## 3. 准备 EFI 分区

1. 把仓库 `EFI/` 放到 FAT32 U 盘或 ESP 根目录（`EFI/BOOT/BOOTx64.efi` 必须在）。
2. 做 Recovery/安装盘时，在 U 盘根目录另建：

   ```text
   com.apple.recovery.boot/
     BaseSystem.dmg
     BaseSystem.chunklist
   ```

   只有 `boot.efi` 和 `BootKernelExtensions.kc` 会停在 `Still waiting for root device.`。

## 4. BIOS 设置

- 关闭 **Secure Boot**
- 关闭 **Fast Boot**
- 使用 **UEFI** 启动
- 从 U 盘/ESP 选择 OpenCore

## 5. 首次启动

1. OpenCore 选择 macOS 系统卷。
2. 进入桌面后先完成触控板设置（见 [TOUCHPAD.md](TOUCHPAD.md)）：
   - 轻点来点按：开
   - 辅助点击：双指轻点
   - 使用触控板来拖移：关
3. 音频/麦克风冷启动无声或无法识别时，睡眠再唤醒。
4. Wi-Fi：冷启动/热启动均已实测可用；若遇异常，断电冷启动可恢复。
5. 重新登录 iMessage/App Store（如果换过三码）。
6. AirDrop：EFI 已内置 AWDL 版 AirportItlwm + BlueToolFixup advsets 与 `-itlawdl*` / `-btlfxadvsets*` 参数；不要同时启用 `itlwm.kext` 或其他 AirportItlwm。替换、验证与回滚见 [AIRDROP.md](AIRDROP.md)。

## 6. 急救盘

建议保留一个与内置 EFI 同版本的 U 盘 EFI：

```text
USB-EFI/
  EFI/
    BOOT/
    OC/
  EFI.bak-<时间戳>/     # 旧版本
```

更新急救盘前先备份旧 `EFI`；启动异常时用旧 `EFI.bak-*` 或内置 ESP 的备份恢复。

## 7. 恢复 / 回滚

- 内置 ESP 恢复：挂载卷标为 `NO NAME` 的 ESP，替换 `EFI/`。
- U 盘急救 EFI 恢复：替换 U 盘 `EFI/`。
- 修改三码/VBIOS 前先备份 `EFI/OC/config.plist`；无法启动时恢复旧 config。

## 8. 注意

- 仓库不包含真实序列号、VBIOS、OpenCore 日志、NVRAM、SysReport。
- `Kernel → Block` 中保留了 `AppleUSBAudio` / `IOAudioFamily` 屏蔽项（配合 VoodooHDA），不要随意打开 AppleALC。
- 系统升级前备份 EFI；升级后先验证 RembrandtGfx 与 VoodooI2C 是否仍工作。
