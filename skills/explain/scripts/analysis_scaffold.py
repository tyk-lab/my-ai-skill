#!/usr/bin/env python3
"""Create or migrate a profile-aware multipage drawio scaffold after confirmation."""

from __future__ import annotations

import argparse
import html
import re
import xml.etree.ElementTree as ET
from pathlib import Path


COMMON_REQUIRED = [
    ("00-核心认知与阅读地图", "项目目的、核心价值、领域对象、核心要点、关键约束和阅读主线"),
    ("01-软件工程总体框架", "静态职责、动态协作、数据状态、资源、平台与外部边界"),
    ("02-构建启动与运行生命周期", "从源码和配置到产物、启动、稳态运行、停止或重启"),
    ("03-端到端核心主线", "1-3 条代表性输入到输出或反馈闭环"),
    ("04-核心行为与调用链", "主线上的真实函数、组件、任务或处理器调用"),
    ("05-数据配置与状态", "配置来源、数据转换、运行状态、持久化、缓存及恢复"),
    ("06-执行模型时间与并发", "执行上下文、调度、时间机制、共享状态和竞态边界"),
    ("07-资源所有权与生命周期", "资源分配或注册、所有者、访问者、停用或释放、冲突和恢复"),
    ("08-外部接口与集成边界", "用户、硬件、协议、API、文件、存储、消息或第三方契约"),
    ("09-故障安全诊断与恢复", "错误检测、传播、诊断、安全保护、降级、回退和恢复"),
    ("10-构建测试调试与演进", "构建矩阵、测试层次、调试观测、发布、扩展点和修改影响"),
]

EMBEDDED_REQUIRED = [
    ("11-中断DMA与实时执行", "中断源、优先级、屏蔽、DMA、ISR 交接、注册和停用"),
    ("12-MCU时钟时间与调度", "时钟树、Tick、硬件 Timer、软件超时、周期任务和溢出"),
    ("13-内存布局与管理", "Flash/RAM、静态区、栈、堆、固定缓冲区、DMA、缓存和容量"),
    ("14-外设资源所有权与冲突", "Pin mux、外设、IRQ/DMA 通道的占用、复用、释放和冲突检查"),
    ("15-芯片板级与安全约束", "HAL、芯片板卡差异、寄存器、电气时序、看门狗和危险输出"),
]

GENERAL_REQUIRED = [
    ("11-进程线程异步与任务生命周期", "进程线程、请求、事件循环、任务、取消、超时和共享状态"),
    ("12-存储事务缓存与一致性", "数据库、文件、缓存、消息、事务、一致性、幂等和恢复"),
    ("13-运行资源池与生命周期", "连接池、线程池、句柄、会话、缓存和外部客户端生命周期"),
    ("14-部署观测与运行安全", "配置密钥、部署、健康检查、日志指标追踪、授权和故障隔离"),
]

OPTIONAL = [
    ("16-关键状态机与生命周期", "对核心目标有决定作用的状态、迁移、退出和恢复路径"),
    ("17-关键算法与领域原理", "决定核心行为的算法、公式、协议或领域约束"),
    ("18-性能容量与边界", "实时预算、吞吐、延迟、容量、退化点和测量方式"),
]

DOCS_REQUIRED = [
    ("00-核心认知与阅读地图", "知识目标、核心要点、关键约束和推荐阅读主线"),
    ("01-知识框架与职责分层", "主题、推导、脚本、演示和配图的职责边界"),
    ("02-推荐阅读与学习主线", "从总入口到主题、推导、图示和演示验证"),
    ("03-主题推导演示引用链", "主题、推导、脚本、配图和演示的真实引用关系"),
    ("04-内容生成验证与维护", "内容和资产如何生成、预览、验证、更新及演进"),
    ("05-读者入口与外部工具边界", "读者入口、交互演示、配图资产和外部编辑工具"),
]

NUMBERED_CONTENT_DIR = re.compile(r"^\d{2}_")
DOCS_ENTRY_DOCS = {"00_阅读引导.md"}
DOCS_SUPPORT_DIRS = {"_scripts", "_demos", "_figures"}
OUTPUT_NAME = "PROJECT_ANALYSIS.drawio"


def detect_profile(root: Path) -> str:
    names = {path.name for path in root.iterdir()} if root.exists() else set()
    if DOCS_ENTRY_DOCS & names:
        return "docs"
    if any(NUMBERED_CONTENT_DIR.match(name) for name in names) and DOCS_SUPPORT_DIRS & names:
        return "docs"

    embedded_markers = {
        "platformio.ini",
        "sdkconfig",
        "zephyr",
        "boards",
        "variants",
        "firmware",
    }
    if embedded_markers & {name.lower() for name in names}:
        return "embedded"
    ino_patterns = ("*.ino", "*/*.ino", "*/*/*.ino")
    if any(any(root.glob(pattern)) for pattern in ino_patterns):
        return "embedded"
    hal_paths = (root / "HAL", root / "src" / "HAL", root / "Marlin" / "src" / "HAL")
    if any(path.is_dir() for path in hal_paths):
        return "embedded"
    return "general"


def drawio_page(title: str, prompt: str, page_id: str) -> str:
    value = html.escape(f"{title}\n\n待补充: {prompt}\n证据: file:line\n状态: [需深挖]")
    return f"""<diagram name="{html.escape(title)}" id="{page_id}">
    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1169" pageHeight="827" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="title" value="{value}" style="rounded=0;whiteSpace=wrap;html=1;align=left;verticalAlign=top;spacing=12;fontSize=16;" vertex="1" parent="1">
          <mxGeometry x="40" y="40" width="640" height="180" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>"""


def drawio_xml(pages: list[tuple[str, str]]) -> str:
    page_xml = [
        drawio_page(title, prompt, f"analysis-page-{index:02d}")
        for index, (title, prompt) in enumerate(pages)
    ]
    return '<mxfile host="app.diagrams.net" agent="Codex">\n  ' + "\n  ".join(page_xml) + "\n</mxfile>\n"


def extract_pages(path: Path) -> list[str]:
    source = path.read_text(encoding="utf-8")
    ET.fromstring(source)
    pages = re.findall(r"<diagram\b[^>]*>.*?</diagram>", source, flags=re.DOTALL)
    if not pages:
        raise ValueError(f"No <diagram> page found in {path}")

    renamed = []
    for index, page in enumerate(pages):
        opening_end = page.index(">")
        opening = page[:opening_end]
        page_name = path.stem if index == 0 else f"{path.stem}-子页-{index + 1:02d}"
        escaped_name = html.escape(page_name, quote=True)
        if re.search(r'\bname="[^"]*"', opening):
            opening = re.sub(r'\bname="[^"]*"', f'name="{escaped_name}"', opening, count=1)
        else:
            opening += f' name="{escaped_name}"'
        renamed.append(opening + page[opening_end:])
    return renamed


def merge_existing(out_dir: Path, target: Path, force: bool, remove_sources: bool) -> int:
    sources = sorted(path for path in out_dir.glob("[0-9][0-9]-*.drawio") if path != target)
    if not sources:
        print(f"No legacy project-analysis drawio files found in {out_dir}.")
        return 2
    if target.exists() and not force:
        print(f"Refusing to overwrite {target}. Re-run with --force only after explicit overwrite confirmation.")
        return 2

    pages = [page for source in sources for page in extract_pages(source)]
    merged = '<mxfile host="app.diagrams.net" agent="Codex">\n  ' + "\n  ".join(pages) + "\n</mxfile>\n"
    ET.fromstring(merged)
    target.write_text(merged, encoding="utf-8", newline="\n")

    if remove_sources:
        for source in sources:
            source.unlink()

    print(f"{target} ({len(pages)} pages)")
    if remove_sources:
        print(f"Removed {len(sources)} legacy drawio files after successful XML validation.")
    else:
        print("Legacy drawio files were retained. Use --remove-sources only after explicit deletion confirmation.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", default=".", help="Project root.")
    parser.add_argument(
        "--profile",
        choices=("auto", "embedded", "general", "docs"),
        default="auto",
        help="Analysis profile. Auto-detect by default.",
    )
    parser.add_argument(
        "--include-optional",
        action="store_true",
        help="Also scaffold optional analysis pages for embedded/general profiles.",
    )
    parser.add_argument("--write", action="store_true", help="Actually write files. Without this, only prints the plan.")
    parser.add_argument("--force", action="store_true", help="Allow overwriting the existing multipage file after explicit confirmation.")
    parser.add_argument("--merge-existing", action="store_true", help="Merge legacy numbered drawio files into one multipage file.")
    parser.add_argument("--remove-sources", action="store_true", help="Delete legacy files after a successful merge and XML validation.")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    out_dir = root / ".project-analysis"
    profile = detect_profile(root) if args.profile == "auto" else args.profile
    required = {
        "embedded": COMMON_REQUIRED + EMBEDDED_REQUIRED,
        "general": COMMON_REQUIRED + GENERAL_REQUIRED,
        "docs": DOCS_REQUIRED,
    }[profile]
    pages = required + (OPTIONAL if args.include_optional and profile != "docs" else [])
    target = out_dir / OUTPUT_NAME

    if args.remove_sources and not args.merge_existing:
        parser.error("--remove-sources requires --merge-existing")
    if args.merge_existing:
        if args.write:
            parser.error("--merge-existing writes directly; do not combine it with --write")
        return merge_existing(out_dir, target, args.force, args.remove_sources)

    if not args.write:
        print(f"Dry run. Analysis profile: {profile}. Re-run with --write after user confirmation.")
        print(target)
        for title, _ in pages:
            print(f"  page: {title}")
        print("Then complete all pages and write .project-analysis/PROJECT_ANALYSIS.md from their actual content.")
        return 0

    if target.exists() and not args.force:
        print("Refusing to overwrite the existing multipage file. Re-run with --force only after explicit overwrite confirmation.")
        print(target)
        return 2

    out_dir.mkdir(parents=True, exist_ok=True)
    target.write_text(drawio_xml(pages), encoding="utf-8", newline="\n")
    print(target)
    print(f"Created {len(pages)} pages.")
    print("After completing and verifying all pages, write .project-analysis/PROJECT_ANALYSIS.md from their actual content.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
