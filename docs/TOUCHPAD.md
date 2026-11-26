# 触控板：VoodooI2C + 系统原生轻点

> 本页为 `main`（RembrandtGfx）基线的触控板配置；`radeonized-680m` 分支沿用该配置，但未在本分支复测。

## 硬件

本机触控板是 **I2C HID**（不是 PS/2），ACPI 拓扑：

| ACPI 设备 | 标识 | 作用 |
|---|---|---|
| `I2CA` | `AMDI0010` | AMD DesignWare I2C 控制器 |
| `GPIO` | `AMDI0030` | GPIO 控制器（触控板中断） |
| `TPDD` | `PNP0C50` | HID-over-I2C 触控板（Precision Touchpad） |

## 当前方案

启用：

- `VoodooI2C.kext` 2.9.1
- `VoodooI2C.kext/Contents/PlugIns/VoodooI2CServices.kext`
- `VoodooI2C.kext/Contents/PlugIns/VoodooGPIO.kext`（内含 `VoodooGPIOAMD`，匹配 `AMDI0030`）
- `VoodooI2CHID.kext` 1.0（匹配 `PNP0C50`）
- `VoodooPS2Controller.kext` 2.3.7 + `VoodooInput.kext` 1.1.6（上游版，供 PS/2 键盘/触控链路复用；触控板本身走 I2C）
- `VoodooPS2Keyboard.kext`（内置键盘）

关闭：

- `VoodooPS2Trackpad.kext`
- `VoodooPS2Mouse.kext`
- `VoodooI2C.kext/Contents/PlugIns/VoodooInput.kext`（本仓库已删除该未使用的自定义副本）

## 为什么不用自定义 VoodooInput

曾尝试 `MacVodooWithBetterDragSupport` 的自定义 `VoodooInput.kext` 1.1.7（`libinput` 风格轻点/双击拖拽）。它在双击判定上使用固定 **180 ms** 窗口，而本机 Precision 触摸板表现为：

- 单击正常
- 双击文字能选中（clickCount=2 正常）
- **Finder 里双击文件/文件夹打不开**
- 三击无法全选

因此最终改回上游 `VoodooInput` 1.1.6，并让 macOS 自己处理轻点/双击/三击。代价是失去“轻点双击拖拽”，但双击打开、三击全选和双击速度调节都恢复为系统标准行为。

## 必需的 macOS 设置

系统设置 → 触控板：

- **轻点来点按：开**
- **辅助点击：双指轻点**
- **使用触控板来拖移：关**（辅助功能 → 指针控制 → 触控板选项）

双击速度：在系统设置里搜索“双击速度”，按习惯调整；该滑块只对系统原生轻点生效（这也是换回上游 VoodooInput 的原因之一）。

## 排障

1. 确认 kext 加载：

   ```sh
   kmutil showloaded | grep -i -E 'voodoo|i2c'
   ```

   应看到 `VoodooI2C 2.9.1`、`VoodooI2CHID`、`VoodooGPIO`、`VoodooI2CServices`、`VoodooInput 1.1.6`。

2. 确认 ACPI 设备存在：

   ```sh
   ioreg -p IOACPIPlane -l -w0 | grep -A8 -E 'I2CA|TPDD|GPIO'
   ```

3. 如果触摸板完全无反应：
   - 先确认没有同时启用两份 `VoodooInput.kext`；
   - 尝试启动参数 `-vi2c-force-polling`（GPIO 中断不可用时退回轮询）；
   - 若日志提示找不到 GPIO/中断，需要针对本机 DSDT 补 `SSDT-GPIO`/`_CRS`；不要直接套用其他机型的 SSDT。

4. 如果装回自定义 VoodooInput 后双击打不开：这不是设置问题，是 180 ms 窗口与 Precision 触摸板不匹配；按本文换回上游 1.1.6。
