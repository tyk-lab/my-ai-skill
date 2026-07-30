---
name: record-decisions
description: "Record or explicitly retrieve cross-project conversation memory in a persistent local history: aligned understanding, corrections, confirmed directions, and confirmed objects. Use only when the user explicitly asks to record the current discussion, asks to review prior records, or invokes `$record-decisions`, and no project-specific workflow owns the information; never trigger during ordinary discussion."
---

# 记录对话认知与决策

将跨项目或对话级、已对齐的认知与决定追加到 [decision-log.md](decision-log.md)，让后续对话能按历史恢复共识。

## 触发边界

- 仅在用户明确要求记录当前讨论（如“记录一下”“把这个记下来”“保存本次对齐”）、明确要求查看既有记录，或显式调用 `$record-decisions` 时执行。
- 不因出现“决策”“结论”“选择”“记录”等词自动触发；讨论本技能本身的配置也不是一次记录请求。
- 普通总结、分析、实施任务和后续对话默认不读取、不写入此文件。

## 与项目专用技能的边界

- 项目内的专用记录规则与技能优先。本技能不替代项目的进度、计划、调试、实验或工程规则记录机制。
- 当前决策属于单一项目的路线、验收、进度、调试结论或实验事实时，交给该项目的专用工作流处理；例如 `project-progress` 应写入其 `.project-plans/` 体系。
- 本技能只记录跨项目的协作偏好、长期工作约定或不归属任何单一项目的认知与决定；不得向项目目录写入文件，也不得复制项目专用记录。
- 一次请求同时包含通用与项目决策时，分别记录到对应位置。归属不清时，先请用户确认，不猜测。

## 工作流程

1. 若用户要求查阅，仅读取 `decision-log.md`，按主题和最新的“取代关系”回答；不要修改文件。
2. 若用户要求记录，先判断是否已有更具体的项目记录机制；如有，遵循其规则并停止本技能的写入流程。
3. 从当前对话提取已明确的认知对齐、纠正事项、确定方向或对象。不要把推测、未获确认的建议、逐轮聊天内容或敏感凭据写入日志。
4. 读取 `decision-log.md`，检查是否已记录同一事项；若是，避免重复追加。纠正旧结论时，追加新条目并写明其取代对象。
5. 按既有 Markdown 格式将新条目追加到文件末尾。使用当天日期；信息缺失时填“未说明”，不要臆造。
6. 若当前对话没有可辨识的已确认信息，说明缺少的最小信息并请用户补充，不写空记录。
7. 回复中简要说明记录或查阅的主题、状态和文件路径，或说明已路由至项目专用机制。

## 条目格式

```markdown
## YYYY-MM-DD — <主题>

- 类型：认知对齐 | 纠正 | 方向确认 | 对象确认 | 长期约定
- 状态：已确认 | 暂定
- 已对齐认知：<后续 AI 应据此理解和行动的结论>
- 纠正：<旧认知 → 新认知；无则“无”>
- 已确认方向/对象：<方向、范围或具体对象；无则“未说明”>
- 依据：<讨论中确认的原因；无则“未说明”>
- 范围：<受影响对象或边界；无则“未说明”>
- 后续：<行动项或“无”>
- 取代关系：<被本条修正或取代的历史条目；无则“无”>
```

保持历史条目不变；需要修正时，追加一条说明取代关系的新记录，而非重写原记录。优先简洁、可检索和因果清晰，而非完整复述对话。
