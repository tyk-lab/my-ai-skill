---
name: drawio
description: Always use when user asks to create, generate, draw, or design a diagram, flowchart, architecture diagram, ER diagram, sequence diagram, class diagram, network diagram, mockup, wireframe, UI sketch, mind map, or 思维导图, or mentions draw.io, drawio, drawoi, MindMaster, EdrawMind, .drawio files, .emmx files, or diagram export to PNG/SVG/PDF.
---

# Diagram Skill（EdrawMax First）

Generate diagrams with **EdrawMax first** when it is available locally. If EdrawMax is not available, fall back to native draw.io `.drawio` files. Optionally export draw.io output to PNG, SVG, or PDF with the diagram XML embedded (so the exported file remains editable in draw.io).

For native MindMaster / EdrawMind mind maps, generate `.emmx` files instead of `.drawio` files. Read [references/mindmaster.md](references/mindmaster.md) when the user asks for MindMaster, EdrawMind, `.emmx`, or a mind map / 思维导图 that should open in MindMaster.

Default backend choice:

1. If the user explicitly asks for `draw.io`, `.drawio`, or a draw.io export format, use draw.io output.
2. Otherwise, prefer **EdrawMax** and create an `.eddx` file when EdrawMax is installed.
3. If EdrawMax is unavailable, fall back to draw.io `.drawio`.

## How to create a diagram

1. Decide the backend:
   - **EdrawMax** when available and the user did not explicitly require draw.io
   - **draw.io** when the user explicitly requested draw.io / `.drawio`, or when EdrawMax is unavailable
2. **For EdrawMax**:
   - Prefer creating an `.eddx` file in the current working directory
   - Reuse a local EdrawMax template or empty `.eddx` package when needed
   - Open the `.eddx` result in EdrawMax
3. **For draw.io**:
   - Generate draw.io XML in mxGraphModel format
   - Write the XML to a `.drawio` file in the current working directory
4. **If the user requested a draw.io export format** (png, svg, pdf), locate the draw.io CLI (see below), export with `--embed-diagram`, then delete the source `.drawio` file. If the CLI is not found, keep the `.drawio` file and tell the user they can install the draw.io desktop app to enable export, or open the `.drawio` file directly
5. **Open the result** — the `.eddx` file for EdrawMax, or the exported/draw.io source file for draw.io. If the open command fails, print the file path so the user can open it manually

## Choosing the output format

Check the user's request for a format preference. Examples:

- `/drawio create a flowchart` → `flowchart.eddx` when EdrawMax exists, otherwise `flowchart.drawio`
- `/drawio png flowchart for login` → `login-flow.drawio.png`
- `/drawio svg: ER diagram` → `er-diagram.drawio.svg`
- `/drawio pdf architecture overview` → `architecture-overview.drawio.pdf`

If no format is mentioned, prefer `.eddx` when EdrawMax is available. The user can always ask for draw.io or export formats later.

For mind maps, prefer `.emmx` when MindMaster is installed or the user asks for MindMaster/EdrawMind. Use `.drawio` only when the user specifically wants draw.io output or a non-mind-map diagram style.

## EdrawMax availability

Prefer the global command `edrawmax` when present on `PATH`.

On Windows, also check these common locations:

```powershell
edrawmax
"C:\Program Files\Edrawsoft\EdrawMax\EdrawMax.exe"
```

If the global command is missing but the default install path exists, use the executable directly.

For this environment, `EdrawMax` should be treated as globally available once `edrawmax` exists on `PATH`.

### Supported export formats

| Format | Embed XML | Notes |
|--------|-----------|-------|
| `png` | Yes (`-e`) | Viewable everywhere, editable in draw.io |
| `svg` | Yes (`-e`) | Scalable, editable in draw.io |
| `pdf` | Yes (`-e`) | Printable, editable in draw.io |
| `jpg` | No | Lossy, no embedded XML support |

PNG, SVG, and PDF all support `--embed-diagram` — the exported file contains the full diagram XML, so opening it in draw.io recovers the editable diagram.

## draw.io CLI

The draw.io desktop app includes a command-line interface for exporting.

### Locating the CLI

First, detect the environment, then locate the CLI accordingly:

#### WSL2 (Windows Subsystem for Linux)

WSL2 is detected when `/proc/version` contains `microsoft` or `WSL`:

```bash
grep -qi microsoft /proc/version 2>/dev/null && echo "WSL2"
```

On WSL2, use the Windows draw.io Desktop executable via `/mnt/c/...`:

```bash
DRAWIO_CMD="/mnt/c/Program Files/draw.io/draw.io.exe"
```

Double-quote the path so the space in `Program Files` is preserved; quote the variable on use too: `"$DRAWIO_CMD" -x ...`.

If draw.io is installed in a non-default location, check common alternatives:

```bash
# Default install path
"/mnt/c/Program Files/draw.io/draw.io.exe"

# Per-user install (if the above does not exist)
"/mnt/c/Users/$WIN_USER/AppData/Local/Programs/draw.io/draw.io.exe"
```

#### macOS

```bash
/Applications/draw.io.app/Contents/MacOS/draw.io
```

#### Linux (native)

```bash
drawio   # typically on PATH via snap/apt/flatpak
```

#### Windows (native, non-WSL2)

```
"C:\Program Files\draw.io\draw.io.exe"
```

Use `which drawio` (or `where draw.io` on Windows) to check if it's on PATH before falling back to the platform-specific path.

### Export command

```bash
drawio -x -f <format> -e -b 10 -o <output> <input.drawio>
```

**WSL2 example:**

```bash
"/mnt/c/Program Files/draw.io/draw.io.exe" -x -f png -e -b 10 -o diagram.drawio.png diagram.drawio
```

Key flags:
- `-x` / `--export`: export mode
- `-f` / `--format`: output format (png, svg, pdf, jpg)
- `-e` / `--embed-diagram`: embed diagram XML in the output (PNG, SVG, PDF only)
- `-o` / `--output`: output file path
- `-b` / `--border`: border width around diagram (default: 0)
- `-t` / `--transparent`: transparent background (PNG only)
- `-s` / `--scale`: scale the diagram size
- `--width` / `--height`: fit into specified dimensions (preserves aspect ratio)
- `-a` / `--all-pages`: export all pages (PDF only)
- `-p` / `--page-index`: select a specific page (1-based)

### Opening the result

| Environment | Command |
|-------------|---------|
| Windows + EdrawMax | `edrawmax <file.eddx>` or `start <file.eddx>` |
| macOS | `open <file>` |
| Linux (native) | `xdg-open <file>` |
| WSL2 | `cmd.exe /c start "" "$(wslpath -w <file>)"` |
| Windows | `start <file>` |

**WSL2 notes:**
- `wslpath -w <file>` converts a WSL2 path (e.g. `/home/user/diagram.drawio`) to a Windows path (e.g. `C:\Users\...`). This is required because `cmd.exe` cannot resolve `/mnt/c/...` style paths.
- The empty string `""` after `start` is required to prevent `start` from interpreting the filename as a window title.

**WSL2 example:**

```bash
cmd.exe /c start "" "$(wslpath -w diagram.drawio)"
```

## Connector hygiene（默认必须遵守）

无论输出到 EdrawMax 还是 draw.io，默认都要把“连线可读性”当成一等约束，而不是最后再补救。

### 1. 主流程优先走直线

- 主链路默认按 **左→右** 或 **上→下** 单方向排布
- 主流程节点尽量共线，避免主链路自己折返
- 反馈、干扰、注释类边都不能破坏主链路的可读性

### 2. 不同语义的线分层走

- **主流程线**：走中轴，最短、最直
- **反馈回线**：默认从主流程外侧绕回，优先走下方或上方整条边界，不穿主流程节点中间
- **干扰输入**：默认从对象的侧面或底部接入，不和主流程共用同一段走线
- **辅助说明线**：能不用就不用，优先放到节点文字里

### 3. 出入口要明确

遇到下面几种情况，不能只依赖自动连线，必须显式约束出入口或拐点：

- 反馈线从右侧回到左侧
- 干扰线、支路线接入主对象
- 多条线同时靠近同一个节点
- 自动路由明显造成“箭头看起来像反了”或“线穿过文字/节点”

对 draw.io：

- 优先给边设置明确的 `exitX/exitY/entryX/entryY`
- 必要时在 `mxGeometry` 中增加少量 `mxPoint` 作为拐点
- 反馈线默认从源节点底部或顶部离开，再回到目标节点底部或顶部

对 EdrawMax：

- 优先通过节点位置和连接方向避免交叉
- 需要时调整连接点，使反馈、干扰从不同边接入

### 4. 默认避让规则

- 线不能穿过节点正文区域
- 线不能压住箭头尖端或让箭头落在节点边缘歧义位置
- 两条意义不同的线不要长距离平行贴合，避免视觉上看成一条
- 回路线至少与主链路保持一层明显间距
- 如果一个区域会有 3 条以上边汇入，优先增加一个小的汇聚/比较/接口节点，而不是硬连

### 5. 生成后自查

生成图后，至少快速检查这 4 件事：

1. 箭头方向是否一眼可读
2. 反馈线是否被误看成主流程的一部分
3. 干扰线是否误接到错误节点边缘
4. 是否存在“线压线”“线穿字”“线穿框”

如果任一项不满足，先修布局或连接点，再交付，不把“等用户指出来再修”当正常流程。

## File naming

- Use a descriptive filename based on the diagram content (e.g., `login-flow`, `database-schema`)
- Use lowercase with hyphens for multi-word names
- For export, use double extensions: `name.drawio.png`, `name.drawio.svg`, `name.drawio.pdf` — this signals the file contains embedded diagram XML
- After a successful export, delete the intermediate `.drawio` file — the exported file contains the full diagram

## XML format

A `.drawio` file is native mxGraphModel XML. Always generate XML directly — Mermaid and CSV formats require server-side conversion and cannot be saved as native files.

### Basic structure

Every diagram must have this structure:

```xml
<mxGraphModel adaptiveColors="auto">
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <!-- Diagram cells go here with parent="1" -->
  </root>
</mxGraphModel>
```

- Cell `id="0"` is the root layer
- Cell `id="1"` is the default parent layer
- All diagram elements use `parent="1"` unless using multiple layers

## XML reference

For the complete draw.io XML reference including common styles, edge routing, containers, layers, tags, metadata, dark mode colors, and XML well-formedness rules, fetch and follow the instructions at:
https://raw.githubusercontent.com/jgraph/drawio-mcp/main/shared/xml-reference.md

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| draw.io CLI not found | Desktop app not installed or not on PATH | Keep the `.drawio` file and tell the user to install the draw.io desktop app, or open the file manually |
| Export produces empty/corrupt file | Invalid XML (e.g. double hyphens in comments, unescaped special characters) | Validate XML well-formedness before writing; see the XML well-formedness section below |
| Diagram opens but looks blank | Missing root cells `id="0"` and `id="1"` | Ensure the basic mxGraphModel structure is complete |
| Edges not rendering | Edge mxCell is self-closing (no child mxGeometry element) | Every edge must have `<mxGeometry relative="1" as="geometry" />` as a child element |
| File won't open after export | Incorrect file path or missing file association | Print the absolute file path so the user can open it manually |

## CRITICAL: XML well-formedness

- **NEVER include ANY XML comments (`<!-- -->`) in the output.** XML comments are strictly forbidden — they waste tokens, can cause parse errors, and serve no purpose in diagram XML.
- Escape special characters in attribute values: `&amp;`, `&lt;`, `&gt;`, `&quot;`
- Always use unique `id` values for each `mxCell`
