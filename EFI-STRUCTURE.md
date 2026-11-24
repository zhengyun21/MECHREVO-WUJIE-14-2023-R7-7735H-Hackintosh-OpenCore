# 旧 EFI 结构（legacy-2026-11 快照）

此分支只保留 2026-11-21 旧仓库的文档与脚本，**不包含** config.plist、VBIOS、config-backups 与 EFI 二进制。
以下为当时仓库 EFI/ 的结构清单，供对照。

## 顶层

- EFI/BOOT/BOOTx64.efi
- EFI/OC/OpenCore.efi

## Kexts

- AMFIPass.kext
- AirportItlwm.kext
- AmdTscSync.kext
- AppleALC.kext
- AppleMCEReporterDisabler.kext
- CryptexFixup.kext
- GenericUSBXHCI.kext
- HibernationFixup.kext
- Lilu.kext
- NVMeFix.kext
- NootedRed.kext
- RembrandtGfx.kext
- RestrictEvents.kext
- SMCBatteryManager.kext
- USBToolBox.kext
- UTBMap.kext
- VirtualSMC.kext
- VoodooI2C.kext（含 VoodooGPIO / VoodooI2CServices / VoodooInput 插件）
- VoodooI2CHID.kext
- VoodooPS2Controller.kext（含 4 个插件）
- WhateverGreen.kext

## ACPI

- SSDT-CPUR.aml
- SSDT-EC-USBX.aml
- SSDT-EC-USBX-Intel-backup-2026-10-29.aml
- SSDT-EC.aml
- SSDT-OCMARK.aml
- SSDT-PLUG-ALT-16CPU.aml
- SSDT-SBUS-MCHC.aml

## Drivers

- OpenCanopy.efi
- OpenHfsPlus.efi
- OpenRuntime.efi
- OpenVariableRuntimeDxe.efi
- ResetNvramEntry.efi

## Tools

- OpenShell.efi

## 说明

旧配置与备份已从公开历史中移除；当前可用配置见 main 分支。
