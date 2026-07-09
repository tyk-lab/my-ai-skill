#!/usr/bin/env python3
"""Create project-analysis drawio and overview scaffolds after confirmation."""

from __future__ import annotations

import argparse
import html
import re
from pathlib import Path


REQUIRED = [
    ("00-总览", "项目目的、核心价值、技术栈、构建/运行入口、理解主线"),
    ("01-系统架构与模块边界", "核心模块、职责边界、依赖方向、入口/出口、跨模块协作"),
    ("02-核心运行流程", "从启动/入口到核心业务闭环的流程"),
    ("03-核心行为调用链", "1-3 条代表核心行为的调用链，不是全量调用图"),
    ("04-关键数据流与配置影响链", "核心数据、配置项、宏/参数如何进入系统并影响行为"),
    ("05-构建测试与调试入口", "构建环境、测试入口、调试入口、关键命令及来源"),
    ("06-外部接口与集成边界", "外部系统、硬件、协议、文件、API、UI 或用户操作的边界"),
]

OPTIONAL = [
    ("07-状态机与生命周期", "状态集合、触发条件、迁移、退出/恢复路径"),
    ("08-资源生命周期管理", "资源申请、持有、释放与所有权"),
    ("09-并发访问", "共享状态、锁/原子/临界区、竞态风险"),
    ("10-错误传播、日志与诊断", "错误来源、传播路径、日志入口、诊断手段"),
    ("11-初始化顺序", "启动、配置加载、模块注册、硬件/外部服务初始化顺序"),
    ("12-异常处理与恢复策略", "异常检测、冲突、边界输入、失败回退、恢复策略"),
    ("13-领域约束与平台适配", "领域硬约束与平台差异"),
    ("14-安全约束与风险边界", "授权、危险操作、防误用、安全边界、高风险路径"),
    ("15-持久化与状态存储", "长期状态保存/加载、默认值、兼容、损坏恢复"),
]

DOCS_REQUIRED = [
    ("00-总览", "总入口、知识目标、推荐阅读顺序、最重要的理解主线"),
    ("01-系统架构与模块边界", "主题目录、推导目录、脚本、演示、配图的职责边界，不是纯目录树"),
    ("02-核心运行流程", "读者如何从总入口走到主题、推导、图示和演示验证"),
    ("03-核心行为调用链", "最值得讲清的引用链，例如主题文档 → 推导文档 → _figures/_scripts/_demos"),
    ("04-关键数据流与配置影响链", "公式、图片、脚本、演示、索引页之间如何互相支撑"),
    ("05-构建测试与调试入口", "文档、配图、脚本、演示如何生成、预览、验证"),
    ("06-外部接口与集成边界", "对读者暴露的入口、演示页、配图资产和外部编辑工具边界"),
]

NUMBERED_CONTENT_DIR = re.compile(r"^\d{2}_")
DOCS_ENTRY_DOCS = {"00_阅读引导.md", "project_index.md"}
DOCS_SUPPORT_DIRS = {"_scripts", "_demos", "_figures"}


def detect_repo_kind(root: Path) -> str:
    names = {path.name for path in root.iterdir()} if root.exists() else set()
    if DOCS_ENTRY_DOCS & names:
        return "docs-first"
    if any(NUMBERED_CONTENT_DIR.match(name) for name in names) and DOCS_SUPPORT_DIRS & names:
        return "docs-first"
    return "code-first"


def drawio_xml(title: str, prompt: str) -> str:
    value = html.escape(f"{title}\n\n待补充: {prompt}\n证据: file:line\n状态: [需深挖]")
    return f"""<mxfile host="app.diagrams.net">
  <diagram name="{html.escape(title)}" id="{html.escape(title)}">
    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1169" pageHeight="827" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="title" value="{value}" style="rounded=0;whiteSpace=wrap;html=1;align=left;verticalAlign=top;spacing=12;fontSize=16;" vertex="1" parent="1">
          <mxGeometry x="40" y="40" width="640" height="180" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
"""


def overview_md(files: list[tuple[str, str]], repo_kind: str) -> str:
    purpose_heading = "## Project Purpose And Core Direction"
    structure_heading = "## Core Structure"
    notes = "- [待补充] 项目目的、核心价值、理解主线。"
    extra_sections: list[str] = []
    if repo_kind == "docs-first":
        purpose_heading = "## Knowledge Goal And Reading Direction"
        structure_heading = "## Knowledge Structure"
        notes = "- [待补充] 总入口、主题分层、公式推导层、演示验证路径。"
        extra_sections = [
            "",
            "## Reading Paths",
            "",
            "- [待补充] 从总入口到主题、推导、演示的推荐顺序。",
            "",
            "## Theme / Derivation / Demo Links",
            "",
            "- [待补充] 主题文档、推导文档、脚本、演示、配图之间的引用关系。",
        ]

    lines = [
        "# Project Overview",
        "",
        "> Generated scaffold. Replace placeholders with code-backed conclusions.",
        "",
        purpose_heading,
        "",
        notes,
        "",
        structure_heading,
        "",
        "- [待补充] 核心分层、目录职责、主要入口。",
        "",
        "## Drawio Files",
        "",
    ]
    for title, prompt in files:
        lines.append(f"- `{title}.drawio`: {prompt}")
    lines.extend(
        [
            *extra_sections,
            "",
            "",
            "## Evidence And Unknowns",
            "",
            "- [待补充] 已读来源、未读范围、关键 `file:line` 证据。",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", default=".", help="Project root.")
    parser.add_argument("--include-optional", action="store_true", help="Also scaffold optional analysis files.")
    parser.add_argument("--write", action="store_true", help="Actually write files. Without this, only prints the plan.")
    parser.add_argument("--force", action="store_true", help="Allow overwriting existing scaffold files after explicit confirmation.")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    out_dir = root / ".project-analysis"
    repo_kind = detect_repo_kind(root)
    required = DOCS_REQUIRED if repo_kind == "docs-first" else REQUIRED
    files = required + (OPTIONAL if args.include_optional else [])
    planned = [out_dir / f"{title}.drawio" for title, _ in files] + [out_dir / "PROJECT_OVERVIEW.md"]

    if not args.write:
        print(f"Dry run. Repo kind: {repo_kind}. Re-run with --write after user confirmation.")
        for path in planned:
            print(path)
        return 0

    existing = [path for path in planned if path.exists()]
    if existing and not args.force:
        print("Refusing to overwrite existing files. Re-run with --force only after explicit overwrite confirmation.")
        for path in existing:
            print(path)
        return 2

    out_dir.mkdir(parents=True, exist_ok=True)
    for title, prompt in files:
        (out_dir / f"{title}.drawio").write_text(drawio_xml(title, prompt), encoding="utf-8", newline="\n")
    (out_dir / "PROJECT_OVERVIEW.md").write_text(overview_md(files, repo_kind), encoding="utf-8", newline="\n")
    for path in planned:
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
