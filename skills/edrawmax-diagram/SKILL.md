---
name: edrawmax-diagram
description: Create, edit, validate, open, or export diagrams with EdrawMax first and draw.io as a controlled fallback. Use for flowcharts, architecture diagrams, ER diagrams, sequence diagrams, class diagrams, network diagrams, block diagrams, mockups, wireframes, UI sketches, mind maps, 思维导图, or requests mentioning EdrawMax, 亿图图示, draw.io, drawio, MindMaster, EdrawMind, .eddx, .drawio, .emmx, PNG, SVG, or PDF diagram export.
---

# EdrawMax Diagram

生成结构清晰、可编辑且经过验证的图表。优先使用 EdrawMax；仅在用户明确指定 draw.io，或无法可靠生成原生 `.eddx` 时回退到 draw.io。

## 核心流程

1. 提取图表类型、节点、关系、方向、分组、格式和输出路径；缺少低风险细节时自行采用合理默认值。
2. 按“后端选择”确定格式，并读取对应参考文件。
3. 先规划布局，再生成文件；主流程保持单向，反馈和辅助关系走外围。
4. 验证文件结构、文本、连线方向和视觉可读性；发现问题后先修正再交付。
5. 按用户要求打开结果；若打开失败，返回绝对路径和失败原因。

## 后端选择

按以下优先级选择，不要仅通过修改扩展名伪造格式：

1. 用户要求 MindMaster、EdrawMind、`.emmx` 或原生思维导图：读取 [references/mindmaster.md](references/mindmaster.md)。
2. 用户明确要求 draw.io、`.drawio` 或 draw.io 可编辑导出：读取 [references/drawio.md](references/drawio.md)。
3. 其余请求先检测 EdrawMax；可用时读取 [references/edrawmax.md](references/edrawmax.md)，优先创建 `.eddx`。
4. EdrawMax 不可用，或没有经过验证的原生 `.eddx` 生成路径：回退到 `.drawio`，说明实际格式，不声称已经生成 `.eddx`。

输出路径优先采用用户指定位置；未指定时采用当前任务配置的用户交付目录，否则采用当前工作目录。文件名使用能表达内容的英文小写短横线形式。

## 布局与连线

- 不要根据空白模板的当前页尺寸压缩或折返布局；先按内容关系和可读间距规划，EdrawMax 生成脚本会根据内容边界自动扩展页面。
- 主流程默认左到右或上到下，节点共线且不折返。
- 反馈线从主流程外侧绕回；干扰和支线从侧面或底部接入。
- 为多边汇入增加汇聚、比较或接口节点，避免三条以上边直接挤入正文节点。
- 显式设置出入口和必要拐点；禁止线穿框、线穿字、箭头方向歧义及不同语义的线长距离重合。
- 优先通过位置和连接点解决交叉，不依赖自动路由碰运气。

## 输出格式

- 默认交付可编辑源文件：`.eddx`、`.drawio` 或 `.emmx`。
- 用户要求 PNG、SVG 或 PDF 时，同时保留可编辑性；draw.io 导出使用嵌入图表 XML 的双扩展名，例如 `login-flow.drawio.png`。
- 成功生成导出文件后，仅在确认导出内嵌可编辑数据且用户明确要求不保留源文件时，才移除中间 `.drawio`。
- 不覆盖现有文件；只有用户明确要求覆盖时才使用脚本的 `-Force` 或等效选项。

## 交付前验证

至少完成以下检查：

1. 解析 XML 或 ZIP 包，确认必需文件存在且 XML 格式正确。
2. 确认所有元素 ID 唯一、边引用有效、文本已正确转义。
3. 渲染或打开结果，检查箭头、交叉、间距、裁切、线穿字和空白画布。
4. 确认最终路径、扩展名和实际格式一致。

若当前环境无法渲染或打开，明确说明未完成的视觉验证，不把结构验证等同于视觉验证。
