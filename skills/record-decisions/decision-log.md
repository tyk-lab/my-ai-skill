# 对话认知与决策历史

仅在用户明确要求记录当前讨论时追加；需要回顾历史时按主题读取最新且未被取代的条目。

## 2026-08-03 — Quatro ToolBoard 挤出电机循环测试

- 类型：方向确认、对象确认
- 状态：已确认
- 已对齐认知：在 `printer-test-quatroToolBoard.cfg` 的宏区域持续循环测试挤出电机；每轮进料 100 mm，再执行 3 次“退料 20 mm、进料 20 mm”。电机运动期间 `F_UNLOAD` 应保持触发，否则按故障立即关停。
- 纠正：初始测试参数 → 挤出机额定电流固定为 0.5 A，测试速度固定为 8 mm/s。
- 已确认方向/对象：使用 `RUN_MOTOR_TEST` 启动、`STOP_MOTOR_TEST` 停止；提供临时变量 `ignore_f_unload`，默认 `False`，仅当设为 `True` 时忽略全部 `F_UNLOAD` 检查。
- 依据：用户在当前对话中明确指定动作序列、电流、速度及临时信号旁路需求。
- 范围：`printer-test-quatroToolBoard.cfg` 中的挤出机驱动参数、`F_UNLOAD` 事件和电机测试宏。
- 后续：在实际硬件上验证电机方向、8 mm/s 速度、循环动作及 `F_UNLOAD` 故障急停；非临时测试时保持 `ignore_f_unload=False`。
- 取代关系：无
