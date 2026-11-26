# 安装与首次启动（Radeonized 分支）

## 前置条件

- 机械革命无界14 2023（R7-7735H / 680M），BIOS **2.22.1282**
- macOS **Sequoia 15** 或 **Tahoe 26**（本分支在 15.8.3 实测）
- OpenCore + Lilu（本仓库 `EFI/` 已包含）
- SIP/AMFI 足够放松以加载未签名 kext（本仓库配置为 `csr-active-config=0x0FFF`、`amfi=0x80`、`amfi_get_out_of_my_way=0x1`、`SecureBootModel=Disabled`）
- 用于生成 SMBIOS 的 `macserial` / GenSMBIOS

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

## 2. 准备 EFI

1. 把仓库 `EFI/` 放到 FAT32 U 盘或 ESP 根目录；`EFI/BOOT/BOOTx64.efi` 必须在。
2. 做 Recovery/安装盘时，在 U 盘根目录另建：

   ```text
   com.apple.recovery.boot/
     BaseSystem.dmg
     BaseSystem.chunklist
   ```

3. 本分支**不需要 `ATY,bin_image`**；不要手动注入 VBIOS，Radeonized 会从本机 ACPI `VFCT` 读取。

## 3. 安装 RBAMDFramebuffer（必需）

`RembrandtGPU.kext` 已随 EFI；`RBAMDFramebuffer.kext` 必须装进 `/Library/Extensions` 并重建 aux KC。

### 自动脚本（推荐）

在本仓库根目录：

```sh
sudo ./scripts/install-radeonized-framebuffer.sh
```

脚本会：复制 kext → dry-run 到 scratch → 校验集合内 UUID `31B2C56B-0FC6-3F8F-85C1-7DD4A2FBAFA1` → 备份 live aux KC → 写入 → 回读校验；失败自动恢复。

### 手动步骤

```sh
sudo rm -rf /Library/Extensions/RBAMDFramebuffer.kext
sudo cp -R Radeonized/RBAMDFramebuffer.kext /Library/Extensions/
sudo chown -R root:wheel /Library/Extensions/RBAMDFramebuffer.kext

boot=/System/Library/KernelCollections/BootKernelExtensions.kc
sys=/System/Library/KernelCollections/SystemKernelExtensions.kc
live=/Library/KernelCollections/AuxiliaryKernelExtensions.kc
scratch=/private/var/tmp/aux-radeonized.kc

sudo kmutil create -n aux -a x86_64 --allow-missing-kdk \
  -B "$boot" -S "$sys" -A "$scratch" -r /Library/Extensions
sudo kmutil inspect -B "$scratch" --show-kext-uuids | grep 31B2C56B

sudo cp -p "$live" "$live.bak-$(date +%Y%m%d-%H%M%S)"
sudo kmutil create -n aux -a x86_64 --allow-missing-kdk \
  -B "$boot" -S "$sys" -A "$live" -r /Library/Extensions
sudo kmutil inspect -B "$live" --show-kext-uuids | grep 31B2C56B
```

> `--allow-missing-kdk` 必须加；缺少 KDK 时 `kmutil create` 可能什么都不写却退出 0，所以一定要看 `-s "$scratch"` 和 UUID 回读。

## 4. BIOS 设置

- 关闭 **Secure Boot**
- 关闭 **Fast Boot**
- 使用 **UEFI** 启动
- 从 U 盘/ESP 选择 OpenCore

## 5. 首次启动

1. OpenCore 选择 macOS 系统卷（本分支 `Resolution=2560x1600@32`、`UIScale=2`；引导图标应已放大）。
2. 进入桌面后验证显卡：
   ```sh
   system_profiler SPDisplaysDataType
   ioreg -rl -c RembrandtGPUPeer | tr ',' '\n' | grep -E '"(armed|arm_why|vbios_src|acpivbios|fbaccel_on)"='
   ```
   预期：`AMD Radeon 680M`、`Metal 3`、`512 MB`、`armed=1`、`arm_why=0`、`vbios_src=3`、`acpivbios=0`。
3. Wi-Fi：AX210 + AirportItlwm，本分支实测正常；不要同时启用 `itlwm.kext`。
4. 睡眠：**当前失效**，不要依赖；先保存工作。
5. 其他功能（亮度、AirDrop、蓝牙、音频/麦克风、摄像头、触控板、USB、NVMe、外接显示、硬解）未在本分支复测，按需逐项验证。
6. 若换过三码，重新登录 iMessage/App Store。

## 6. 恢复 / 回滚

- **恢复 aux KC**：`sudo cp -p /Library/KernelCollections/AuxiliaryKernelExtensions.kc.bak-<时间戳> /Library/KernelCollections/AuxiliaryKernelExtensions.kc`
- **移除 framebuffer**：`sudo rm -rf /Library/Extensions/RBAMDFramebuffer.kext` 后按上面命令重建 aux KC（或用备份覆盖）。
- **恢复 EFI**：用 U 盘急救 EFI 或内置 ESP 的备份替换 `EFI/`。
- **回退到 main（RembrandtGfx）**：建议直接使用 `main` 分支的完整 EFI；不要混用两套显卡配置。

## 7. 注意

- 本分支的 `rbgpuvblhz=119807Hz` 是本机 120Hz 面板的计时；换面板/刷新率时需调整。
- `-rbgpufbaux` 只武装 AUX/EDID 路径，不主动发事务；不要在不了解的情况下改成写操作。
- 公开版不含真实 SMBIOS、`ATY,bin_image`、OpenCore 日志、NVRAM、SysReport、config 备份。
- 系统升级前备份 EFI 与 aux KC；升级后先验证 Radeonized 是否仍工作。
- Radeonized 许可证：`Radeonized/LICENSE`（MIT）与 `Radeonized/LICENSE.amdgpu`（AMD 微码）；不要剥离 `RembrandtGPU.kext/Contents/Resources/LICENSE.amdgpu`。
