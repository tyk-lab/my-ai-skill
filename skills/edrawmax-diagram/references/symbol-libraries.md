# draw.io 符号库与选型

## 符号来源层级

1. **draw.io 内置语义形状**：流程、架构、控制框图的常见形状（`ellipse`、`rhombus`、`shape=cylinder3`、`shape=document` 等），直接写进 `mxCell` 的 `style`，稳定且可编辑。
2. **技能内置 stencil 库**：技能根目录 `stencils/` 下随附的 draw.io 官方图库，可用 `scripts/sync-drawio-stencils.ps1` 下载和更新；符号以 draw.io `shape=stencil(...)` 或内联 `mxGraphModel` 形式嵌入 `.drawio`。
3. **本机 `mxStencil` 图库**：若装有 EdrawMax，其 `config\mxStencil` 下的 AWS、Azure、Cisco 等 stencil 也可查询使用。
4. **简化语义图形**：找不到准确符号时，用基本形状保持对象类别、端口和拓扑。

## 内置图库下载与更新

```powershell
./scripts/sync-drawio-stencils.ps1                          # 下载默认精选集
./scripts/sync-drawio-stencils.ps1 -Name ibm,openstack      # 追加其他库
./scripts/sync-drawio-stencils.ps1 -Force                   # 覆盖更新已有库
```

默认精选集：`aws4`、`azure`、`gcp3`、`kubernetes`、`cisco19`、`networks`、`bpmn`、`flowchart`。
库名对应 drawio 官方仓库 `src/main/webapp/stencils` 中的文件名；图库为 Apache-2.0，
其中厂商 logo 类图标含商标，仅用于图表表达，不用于品牌用途。

## 查询安装符号

查询脚本自动覆盖技能内置 `stencils/` 和本机 EdrawMax 附带的 `config\mxStencil` 两个来源（查询不修改任何目录）：

```powershell
./scripts/get-edrawmax-symbols.ps1 -Source mxstencil -LibrariesOnly
./scripts/get-edrawmax-symbols.ps1 -Source mxstencil -Pattern '*router*' -MaxResults 20
./scripts/get-edrawmax-symbols.ps1 -Source mxstencil -Pattern '*AWS*'
```

输出用于选择图库、库文件和符号名。默认最多显示 100 条，`-MaxResults 0` 可取消限制。

draw.io 桌面版自身也内置大量图库（General、AWS、Azure、GCP、Cisco、Network、Electrical 等），`mxStencil` 查询不到时优先直接使用 draw.io 内置 shape 名。

## 常见类别

安装内容可能随版本变化，常见类别包括：

- 云计算：AWS、Azure、GCP、Kubernetes。
- 网络设备：Cisco、通用网络、机架图。
- 电气与工程：电路元件、工业控制。
- 软件建模：UML、ER、BPMN。

先查询当前机器，不硬编码某个版本必定存在的路径或符号名。

## 选择规则

- 通用语义形状足够表达时，直接使用 draw.io 内置形状，保证自动化和稳定可编辑性。
- 用户要求某种专业符号或参考图明显依赖图标时，必须先查 `mxStencil` 或 draw.io 内置图库；不要未经说明改成普通矩形。
- 嵌入 stencil 符号时，保持其在 draw.io 中可正常打开和编辑；交付仍为 `.drawio` 或带嵌入 XML 的导出文件。
- 找不到准确符号时，可用简化语义图形，但应保持对象类别、端口和拓扑，不用装饰性图标冒充标准符号。
