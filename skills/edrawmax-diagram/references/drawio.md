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

- 所有图元 ID 唯一，普通图元使用 `parent="1"`。
- 每条边包含子元素 `<mxGeometry relative="1" as="geometry"/>`。
- 属性值转义 `&`、`<`、`>` 和 `"`；输出 XML 中不写注释。
- 反馈、支线和多路汇入显式设置 `exitX/exitY/entryX/entryY`；必要时在 `mxGeometry` 中加入少量 `mxPoint` 拐点。
- 使用正交边时检查自动路由结果，不让线穿过节点正文。

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

1. 用 XML 解析器读取 `.drawio`，确认根节点、基础层、唯一 ID 和有效边引用。
2. 导出后确认目标文件存在且大小非零。
3. PNG、SVG 或 PDF 使用 `-e` 时，确认可由 draw.io 重新打开为可编辑图表。
4. 打开或渲染结果，检查空白页、裁切、文本溢出、箭头方向和连线交叉。

成功导出并确认嵌入数据后，只有在用户明确要求不保留源文件时才移除中间 `.drawio`。
