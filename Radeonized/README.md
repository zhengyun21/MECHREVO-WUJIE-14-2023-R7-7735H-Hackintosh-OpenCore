# Radeonized（本仓库打包）

本目录把 **Radeonized v0.1.1** 的 framebuffer 组件和许可证原样收录，供本仓库的 Radeonized 分支使用。

- 上游项目：<https://github.com/FranciumOS-org/Radeonized>
- 上游版本：**v0.1.1**（release tag）

上游作者与贡献者让 AMD Radeon 680M（Rembrandt，`1002:1681`）在 macOS 上获得 Metal 加速，特此致谢。没有上游的工作，本分支的显卡方案不可能成立。

## 目录内容

| 文件 | 用途 |
|---|---|
| `RBAMDFramebuffer.kext` | 自写 IOFramebuffer，负责内屏、亮度与刷新率；安装到 `/Library/Extensions` 并重建 aux KC |
| `LICENSE` | 上游代码的 MIT 许可证（`Copyright (c) 2026 RembrandtGPU contributors`） |
| `LICENSE.amdgpu` | `RembrandtGPU.kext` 内嵌 AMD 微码的二进制许可（原样） |
| `THIRD-PARTY.md` | 上游对二进制内容的第三方声明 |

`RembrandtGPU.kext`（Lilu 插件）在 `EFI/OC/Kexts/` 中，排在 `Lilu.kext` 之后；其 `Contents/Resources/LICENSE.amdgpu` 必须保留，不要剥离。

## UUID（以实际二进制为准）

| Bundle | 实际 Mach-O UUID |
|---|---|
| `RembrandtGPU.kext` | `E3A30962-A898-38B4-856D-402EE1FD0D50` |
| `RBAMDFramebuffer.kext` | `31B2C56B-0FC6-3F8F-85C1-7DD4A2FBAFA1` |

> 上游 `README-INSTALL.md` 里写的 `52930D70…` / `2527A89E…` 是过期值；安装时以 `dwarfdump --uuid` 和 aux KC 内的实际 UUID 为准。

## 安装 framebuffer

需要 macOS 15（Sequoia）或 26（Tahoe）、OpenCore + Lilu、以及足够放松的 SIP/AMFI（本仓库配置为 `csr-active-config=0x0FFF`、`amfi=0x80` / `amfi_get_out_of_my_way=0x1`）。

```sh
sudo ./scripts/install-radeonized-framebuffer.sh
```

脚本会：

1. 把 `Radeonized/RBAMDFramebuffer.kext` 复制到 `/Library/Extensions`；
2. 先 `kmutil create` 到 scratch 路径，校验集合内确实带 `31B2C56B…`；
3. 备份现有 `/Library/KernelCollections/AuxiliaryKernelExtensions.kc`；
4. 写入 live aux KC，并回读确认 UUID；失败自动恢复备份。

手动步骤见 [docs/INSTALL.md](../docs/INSTALL.md)。装好后重启，验证：

```sh
system_profiler SPDisplaysDataType
ioreg -rl -c RembrandtGPUPeer | tr ',' '\n' | grep -E '"(armed|arm_why|vbios_src|acpivbios)"='
```

## 当前实测状态

- 显卡：AMD Radeon 680M，Metal 3，2560×1600 @120Hz，HiDPI 1280×800，**512MB**（UMA carve-out）
- Wi-Fi：正常
- 睡眠/唤醒：**当前失效**
- 其他功能：未在本分支复测
- 不需要 `ATY,bin_image`：VBIOS 由插件从本机 ACPI `VFCT` 读取

上游已知限制：USB-C DP 外接显示未打通、WebGL 抗锯齿、偶发 stall、部分小字形斑点。详见上游 README。

## 许可证

- 代码：MIT（见 `LICENSE`）
- 内嵌 AMD 微码：仅允许二进制再分发；禁止反向工程/反编译/反汇编；必须随附 `LICENSE.amdgpu` 的版权、许可与免责声明（见 `LICENSE.amdgpu` 与 `THIRD-PARTY.md`）
- 上游不包含、也不得再分发任何板卡 VBIOS；本仓库同样不包含 VBIOS
