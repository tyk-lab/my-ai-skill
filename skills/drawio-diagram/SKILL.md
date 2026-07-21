---
name: drawio-diagram
description: Create, edit, validate, open, or export semantically expressive diagrams with draw.io as the default backend. Use for flowcharts, architecture diagrams, ER diagrams, sequence diagrams, class diagrams, network diagrams, block diagrams, timelines, charts, concept maps, mind maps, mockups, wireframes, UI sketches, 思维导图, draw.io, MindMaster, EdrawMind, .drawio, .emmx, PNG, SVG, or PDF diagram export.
---

# Draw.io Diagram

生成结构清晰、符号语义准确、可编辑且经过验证的图表。默认使用 draw.io 原生 `mxGraphModel` 格式；思维导图仍走 MindMaster/EdrawMind 原生格式。不再使用 EdrawMax 生成图表。

## 核心流程

1. 提取图表目的、阅读层级、节点、关系、方向、分组、关键反馈、参考图特征和输出路径。
2. 先选表达范式，再选具体符号：流程图、分层框图、时间线、列表、概念图、网络图等不可混为同一种“方框连线图”。
3. 按“后端与符号来源”确定格式，并读取对应参考文件。
4. 先规划视觉层级和主链路，再生成文件；主流程单向，反馈和辅助关系走外围。
5. 验证结构、文本、箭头、线型、符号语义和视觉可读性；发现问题后修正再交付。

## 参考图与简化原则

- 用户给出参考图时，先提取其拓扑、层级、分区、形状语法、线型语义、色彩角色和视觉重心。
- “画得大致”表示减少代码细节、参数文字和次要分支，不表示删掉主链路、关键队列、反馈回路、模块边界或中断关系。
- 若用户说“像这张图”，优先保持它的布局骨架与表达方式，再替换内容；不要只复用配色。
- 总览图默认只保留 5～9 个一级节点；细节放到第二张图或注释，不在总览图中堆代码级信息。

完整选型规则见 [references/visual-language.md](references/visual-language.md)。

## 后端与符号来源

按以下优先级选择，禁止仅修改扩展名伪造格式：

1. MindMaster、EdrawMind、`.emmx` 或原生思维导图：读取 [references/mindmaster.md](references/mindmaster.md)。
2. 其余所有图表默认使用 draw.io：读取 [references/drawio.md](references/drawio.md)，直接生成 `mxGraphModel` XML 的 `.drawio` 文件，不用 Mermaid 或 CSV 伪装。
3. 通用流程、架构和框图优先使用 draw.io 内置语义形状；专业网络、云、电气、平面图等图表先查询技能内置 `stencils/` 库（可用 `scripts/sync-drawio-stencils.ps1` 下载更新）获取标准符号。
4. 找不到准确符号时，用简化语义图形并保持对象类别、端口和拓扑，不用装饰性图标冒充标准符号。

符号库发现和查询命令见 [references/symbol-libraries.md](references/symbol-libraries.md)。

## 语义符号优先

不要把所有节点画成圆角矩形。默认语义到 draw.io 形状映射如下：

- 开始/结束、状态：`ellipse` 或 `rounded=1`
- 普通过程、模块：`rectangle` 或 `rounded=1`
- 判断、条件：`rhombus`
- 输入/输出：`shape=parallelogram`
- 队列、缓存、数据存储：`shape=cylinder3`
- 文档、报告：`shape=document`
- 子流程、可展开模块：`shape=process` 或双边框样式
- 阶段、推进关系：`shape=chevron`
- 约束、提示：`shape=note`
- 汇聚、控制或特殊处理：按语义选择 `shape=hexagon`、`triangle` 等，必要时查询 `mxStencil` 符号。

形状、颜色和线型应分别承载不同信息：形状表示对象类型，颜色表示职责域或状态，线型表示关系类型。不要仅靠颜色区分所有含义。

## 布局与连线

- 主流程默认从左到右或从上到下，节点共线且不折返。
- 反馈线从主链路外侧绕回；中断、控制和辅助关系从侧面或底部接入。
- 实线表示主流程或强依赖，虚线表示控制、反馈或异步触发，点线表示关联、说明或弱依赖。
- 多边汇入时增加汇聚、接口或调度节点，避免三条以上连线直接挤入正文节点。
- 显式设置 `exitX/exitY/entryX/entryY` 出入口和必要 `mxPoint` 拐点；避免线穿框、线穿字、箭头歧义和标签压线。
- 连线标签只写方向、数据或状态的短语；完整解释放进节点或注释框。
- 优先通过位置、间距和连接点消除交叉，不依赖自动路由碰运气。

## 文字可读性与防重叠

- 节点尺寸按文字量估算，禁止先画框再硬塞文字：宽度 ≥ 最长行字数 × 字号（中文按 1.0×、英文按 0.55× 估算）+ 两侧各 ≥ 8px 内边距；高度 ≥ 行数 × 字号 × 1.4 + 上下各 ≥ 8px 内边距。
- 字号不小于 11px，正文 12～14px；`textColor` 与 `fill` 保持高对比（深底白字、浅底深字），不用浅灰字配浅色底。
- 节点 style 统一带 `whiteSpace=wrap;html=1;`，长文本依赖换行而不是无限加宽。
- 同级节点水平间距 ≥ 60px、垂直间距 ≥ 40px；反馈线和支线通道额外预留 ≥ 40px，不贴边绕行。
- 边标签保持短词，带 `labelBackgroundColor=#FFFFFF` 压在线上方；多条平行边的标签沿线路错开，不堆在同一位置。
- 容器内子节点四周留白 ≥ 20px，标题区高度 ≥ 30px；子节点不得压到容器边框和标题。
- 生成后用包围盒两两检查：节点与节点、标签与节点、标签与连线不得重叠；有重叠先调布局和尺寸，不缩小字号到 11px 以下。

draw.io 具体样式写法见 [references/drawio.md](references/drawio.md)。

## 输出格式

- 默认只交付可编辑源文件：`.drawio` 或 `.emmx`。
- 用户要求 PNG、SVG 或 PDF 时，用 drawio CLI 导出并加 `-e` 嵌入图表 XML，保留可编辑性。
- 不覆盖现有文件；仅在用户明确要求覆盖时才重写已有文件。
- 输出文件名使用能表达内容的英文小写短横线形式，路径优先采用用户指定位置。

## 交付前验证

至少完成以下检查：

1. 用 XML 解析器解析 `.drawio`，确认根节点、基础层 `parent="1"`、元素 ID 唯一、边引用有效、文本正确转义。
2. 导出 PNG、SVG 或 PDF 后确认文件存在且非空；使用 `-e` 时确认可由 draw.io 重新打开为可编辑图表。
3. 打开或渲染结果，检查符号、箭头、线型、交叉、间距、文本溢出、裁切和空白画布。
4. 对照用户原图或需求，确认拓扑和表达层级没有在“简化”中丢失。
5. 确认最终路径、扩展名和实际格式一致。

若环境无法渲染或打开，明确说明未完成的视觉验证；结构验证不能替代视觉验证。
