# draw.io 生成与导出

## 原生 XML

直接生成 `mxGraphModel` XML，不使用 Mermaid 或 CSV 伪装为 `.drawio`。最小结构：

```xml
<mxGraphModel adaptiveColors="auto">
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
  </root>
</mxGraphModel>
```

要求：

- 所有图元 ID 唯一。顶层图元使用 `parent="1"`，分组成员的 `parent` 指向所属容器，不强制所有图元平铺到基础层。
- 每条边包含子元素 `<mxGeometry relative="1" as="geometry"/>`。
- 属性值转义 `&`、`<`、`>` 和 `"`；输出 XML 中不写注释。
- 反馈、支线和多路汇入显式设置 `exitX/exitY/entryX/entryY`；必要时在 `mxGeometry` 中加入少量 `mxPoint` 拐点。
- 使用正交边时检查自动路由结果，不让线穿过节点正文。

## 真实分组与坐标

- 整体操作单元必须建立真实父子层级：标题、成员模块和内部边归属容器。纯装饰背景明确作为背景，不代替分组。
- 子节点的 `mxGeometry.x/y` 相对父容器。已有节点换父层时，保留绝对位置，再减去新父层的绝对原点；嵌套层级逐级换算。
- 内部边放在两端的最近公共容器；跨组边放在最近公共祖先层，`source/target` 仍连接真实节点。路径控制点相对边的父层，换父层时同步转换；标签相对位置及 `offset` 不当作绝对路径点转换。
- 容器可用 `container=1;collapsible=0;`；未设计折叠行为时不自动启用折叠。分组移动应带动成员；边界缩放不自动等于内容等比缩放，需要缩放/折叠时明确所需行为并另验，不承诺未验证的联动。

例如父容器在 `(200,150)`，子节点的局部坐标为 `(24,56)`，则子节点绝对坐标为 `(224,206)`。移动父容器时子节点局部坐标不变。

## CLI 检测

Windows PowerShell 7：

```powershell
$command = Get-Command drawio -ErrorAction SilentlyContinue
$defaultExe = 'C:\Program Files\draw.io\draw.io.exe'
$userExe = Join-Path $env:LOCALAPPDATA 'Programs\draw.io\draw.io.exe'
```

macOS 常见路径为 `/Applications/draw.io.app/Contents/MacOS/draw.io`；原生 Linux 优先使用 PATH 中的 `drawio`。仅在实际存在时调用相应命令。

## 导出

PNG、SVG 和 PDF 使用嵌入图表 XML 的导出：

```powershell
drawio -x -f png -e -b 10 -o 'C:\path\diagram.drawio.png' 'C:\path\diagram.drawio'
```

常用参数：

- `-x`：导出。
- `-f`：`png`、`svg`、`pdf` 或 `jpg`。
- `-e`：嵌入图表 XML；适用于 PNG、SVG、PDF。
- `-b`：边距。
- `-t`：PNG 透明背景。
- `-s`：缩放比例。
- `-a`：导出 PDF 的全部页面。

CLI 不可用时保留 `.drawio` 源文件，不承诺导出成功。JPG 不支持嵌入可编辑 XML。

## 验证

1. 解析 XML，确认根结构、基础层、唯一 ID、有效父引用、无父子循环及有效边引用；分组成员符合预定归属。
2. 已有图重设分组后，确认成员绝对位置及边的端点引用不变，内部边与跨组边的父层正确。
3. 在临时副本中移动一个真实分组，确认成员、标题与内部线随动，外部节点不动，跨组线仍连接目标。可用编辑器移动，或只改变副本父容器坐标再渲染；后者只证明保存模型的移动效果，不声称已做鼠标交互验证。
4. 导出后确认文件存在且非空；使用 `-e` 时确认可重新打开为可编辑图表。未验证时不声称嵌入编辑性通过。
5. 按 [视觉验收](visual-language.md#渲染后的视觉验收) 检查最终渲染与需求拓扑；确认路径、扩展名和实际格式相符。临时移动副本不作为交付图。

成功导出并确认嵌入数据后，只有在用户明确要求不保留源文件时才移除中间 `.drawio`。

## 文字与连线实现

字号、间距、配色和尺寸估算遵循 [视觉规则](visual-language.md)，此处仅定义 draw.io 实现。

- 文本使用 `whiteSpace=wrap;html=1;`，显式设置 `fontSize`。独立标题或说明对象绑定所属模块；简单节点可直接用已转义的 HTML 标题与换行。
- 节点与边样式分开构造。边标签以 `spacing=0;labelWidth=80;labelBackgroundColor=#FFFFFF;` 起步，按短语调整宽度，按所在区域调整背景色，避免中文逐字竖排。
- 边不继承节点大内边距，不混入独立标签节点的 `edgeLabel` 样式。水平标签可用几何 `offset` 放在线上方；拐点、竖线及路径变化后以渲染为准。
- 几何重叠检查先解析父层绝对坐标，排除祖先容器与子节点的有意包含；不直接比较不同父层的局部坐标。

## 可复用的样式片段

以下是起点；节点内容、尺寸和端口仍按拓扑确定。标题可用 HTML 加粗，并在序列化 XML 时转义；不依赖外部字体或图标。

控制职责模块示例（其他职责替换填充与描边色，参照 visual-language.md 的职责色表）：

```text
rounded=1;arcSize=12;whiteSpace=wrap;html=1;fillColor=#EFF6FF;strokeColor=#2563EB;strokeWidth=1.25;fontColor=#0F172A;fontFamily=Microsoft YaHei;fontSize=16;align=left;verticalAlign=middle;spacing=16;shadow=0;
```

同职责中的核心模块保留职责色，可适度加强描边（替换原值，不堆叠冲突属性）：

```text
strokeWidth=2;
```

主链边（不要与节点样式共用内边距）：

```text
edgeStyle=orthogonalEdgeStyle;rounded=0;endArrow=block;endFill=1;strokeColor=#475569;strokeWidth=1.75;fontColor=#334155;fontFamily=Microsoft YaHei;fontSize=14;whiteSpace=wrap;html=1;spacing=0;labelWidth=80;labelBackgroundColor=#FFFFFF;
```

水平边的短标签可先向上移 14px，给箭头和文字各自留出空间；正交边路径变化后重新检查，不把偏移值机械用于竖线：

```xml
<mxGeometry relative="1" as="geometry">
  <mxPoint x="0" y="-14" as="offset"/>
</mxGeometry>
```

边的 `exitX/exitY/entryX/entryY` 和转折 `mxPoint` 必须按具体关系填写。标签比线段宽时优先重排端口或标签，不仅扩大 `labelWidth`；该属性只控制文字布局，不会增加两个节点之间的实际距离。
