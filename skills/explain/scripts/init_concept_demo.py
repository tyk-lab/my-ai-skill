#!/usr/bin/env python3
"""Initialize a single-file interactive concept demo."""

from __future__ import annotations

import argparse
from pathlib import Path


HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>__TITLE__</title>
  <style>
    :root {{
      --bg: #f6f1e8;
      --panel: rgba(255, 251, 245, 0.9);
      --ink: #23303c;
      --muted: #5d6973;
      --grid: #d9ccb7;
      --blue: #1f6aa5;
      --orange: #df7f31;
      --green: #4d8f5a;
      --accent: #a33d2d;
      --shadow: 0 18px 45px rgba(72, 59, 43, 0.12);
    }}

    * {{
      box-sizing: border-box;
    }}

    body {{
      margin: 0;
      font-family: "Microsoft YaHei", "Segoe UI", sans-serif;
      color: var(--ink);
      background:
        radial-gradient(circle at top right, rgba(223, 127, 49, 0.16), transparent 28%),
        radial-gradient(circle at left 20%, rgba(31, 106, 165, 0.12), transparent 28%),
        linear-gradient(180deg, #fbf7ee 0%, #f3eadf 100%);
    }}

    main {{
      max-width: 1180px;
      margin: 0 auto;
      padding: 28px 20px 42px;
    }}

    .hero, .panel, .card {{
      background: var(--panel);
      border: 1px solid rgba(93, 105, 115, 0.12);
      border-radius: 20px;
      box-shadow: var(--shadow);
      backdrop-filter: blur(10px);
    }}

    .hero {{
      padding: 28px;
      margin-bottom: 18px;
    }}

    h1, h2, p {{
      margin: 0;
    }}

    h1 {{
      font-family: Georgia, "Times New Roman", serif;
      font-size: clamp(2rem, 3vw, 3.1rem);
      line-height: 1.06;
      margin-bottom: 12px;
    }}

    .lead {{
      color: var(--muted);
      line-height: 1.72;
      max-width: 54rem;
    }}

    .chips {{
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 16px;
    }}

    .chip {{
      padding: 8px 12px;
      border-radius: 999px;
      color: var(--blue);
      background: rgba(31, 106, 165, 0.1);
      font-size: 0.92rem;
    }}

    .panel {{
      padding: 20px;
      margin-bottom: 18px;
    }}

    .controls {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 16px 20px;
    }}

    .control label {{
      display: flex;
      justify-content: space-between;
      gap: 10px;
      font-weight: 700;
      margin-bottom: 8px;
    }}

    .control small {{
      display: block;
      margin-top: 8px;
      color: var(--muted);
      line-height: 1.6;
    }}

    input[type="range"] {{
      width: 100%;
      accent-color: var(--accent);
    }}

    .readouts {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
      gap: 12px;
      margin-top: 16px;
    }}

    .card {{
      padding: 14px 16px;
    }}

    .label {{
      color: var(--muted);
      font-size: 0.9rem;
      margin-bottom: 6px;
    }}

    .value {{
      font-size: 1.42rem;
      font-weight: 700;
    }}

    .explain-box {{
      padding: 16px 18px;
      border-radius: 14px;
      border: 1px solid rgba(31, 106, 165, 0.18);
      background: rgba(31, 106, 165, 0.08);
      line-height: 1.72;
    }}

    .explain-box strong {{
      color: var(--blue);
    }}

    .explain-box ol {{
      margin: 10px 0 0 1.2em;
      padding: 0;
    }}

    .explain-box li + li {{
      margin-top: 8px;
    }}

    .grid {{
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 18px;
    }}

    .plot-card h2 {{
      font-size: 1.18rem;
      margin-bottom: 8px;
    }}

    .plot-card p {{
      color: var(--muted);
      line-height: 1.62;
      margin-bottom: 12px;
    }}

    svg {{
      width: 100%;
      height: auto;
      display: block;
      border-radius: 16px;
      background: rgba(255, 255, 255, 0.62);
      border: 1px solid rgba(93, 105, 115, 0.12);
    }}

    .formula-block {{
      margin-top: 14px;
      padding: 14px 16px;
      border-left: 4px solid var(--accent);
      border-radius: 12px;
      background: rgba(163, 61, 45, 0.06);
      line-height: 1.68;
    }}

    .formula-block strong {{
      color: var(--accent);
    }}

    .footer {{
      margin-top: 18px;
      color: var(--muted);
      line-height: 1.72;
      font-size: 0.94rem;
    }}

    @media (max-width: 860px) {{
      .grid {{
        grid-template-columns: 1fr;
      }}
    }}
  </style>
</head>
<body>
  <main>
    <section class="hero">
      <h1>__TITLE__</h1>
      <p class="lead">__SUMMARY__</p>
      <div class="chips" id="chips"></div>
    </section>

    <section class="panel">
      <div class="controls" id="controls"></div>
      <div class="readouts" id="readouts"></div>
    </section>

    <section class="panel">
      <div class="explain-box">
        <strong>先看这几点：</strong>
        <ol id="explainPoints"></ol>
      </div>
    </section>

    <section class="grid">
      <article class="panel plot-card">
        <h2 id="leftTitle"></h2>
        <p id="leftIntro"></p>
        <svg id="leftPlot" viewBox="0 0 620 340" aria-label="左图"></svg>
      </article>

      <article class="panel plot-card">
        <h2 id="rightTitle"></h2>
        <p id="rightIntro"></p>
        <svg id="rightPlot" viewBox="0 0 620 340" aria-label="右图"></svg>
      </article>
    </section>

    <section class="panel">
      <div class="formula-block">
        <strong>公式与结论：</strong>
        <div id="formulaText"></div>
      </div>
      <p class="footer">提示：先让页面自己跑起来，再替换成你的真实模型与文案。这个脚手架默认只提供结构，不替你决定物理/数学结论。</p>
    </section>
  </main>

  <script>
    const CONFIG = {{
      chips: [
        "左图放时间/几何/结构视角",
        "右图放频率/参数/对照视角",
        "把直觉结论和公式结论分开写"
      ],
      controls: [
        {{
          id: "speed",
          label: "参数 A",
          min: 0.2,
          max: 3.0,
          step: 0.1,
          value: 1.0,
          unit: "",
          hint: "TODO: 改成你的主参数，例如 τ、阻尼、角速度、斜率。"
        }},
        {{
          id: "ratio",
          label: "参数 B",
          min: 0.2,
          max: 6.0,
          step: 0.1,
          value: 1.0,
          unit: "",
          hint: "TODO: 改成第二参数，例如 f/fc、输入幅度、采样间隔。"
        }}
      ],
      readouts: [
        {{ id: "readoutA", label: "读数 A", value: "0.00" }},
        {{ id: "readoutB", label: "读数 B", value: "0.00" }},
        {{ id: "readoutC", label: "读数 C", value: "0.00" }},
        {{ id: "readoutD", label: "读数 D", value: "0.00" }}
      ],
      explainPoints: [
        "TODO: 写用户最容易混淆的前提条件。",
        "TODO: 写哪条结论只适用于阶跃/静态目标，哪条适用于正弦/稳态。",
        "TODO: 写这个页面真正想证明的一句话。"
      ],
      leftTitle: "1. 左图标题",
      leftIntro: "TODO: 左图一句话。通常放时间域、几何或结构视角。",
      rightTitle: "2. 右图标题",
      rightIntro: "TODO: 右图一句话。通常放频率域、参数对照或结果视角。",
      formulaText: "TODO: 把最关键的 1-3 个公式写在这里，并明确哪些只是时间窗口直觉，哪些是最终稳态结果。"
    }};

    const STATE = Object.fromEntries(CONFIG.controls.map((control) => [control.id, Number(control.value)]));

    const STYLE = getComputedStyle(document.documentElement);
    const COLORS = {{
      grid: STYLE.getPropertyValue("--grid").trim(),
      blue: STYLE.getPropertyValue("--blue").trim(),
      orange: STYLE.getPropertyValue("--orange").trim(),
      green: STYLE.getPropertyValue("--green").trim(),
      ink: STYLE.getPropertyValue("--ink").trim(),
      muted: STYLE.getPropertyValue("--muted").trim(),
      accent: STYLE.getPropertyValue("--accent").trim()
    }};

    function fmt(value, digits = 2) {{
      return Number(value).toFixed(digits);
    }}

    function svgPoint(x, y) {{
      return `${{x.toFixed(2)}},${{y.toFixed(2)}}`;
    }}

    function mapX(value, min, max, left, width) {{
      return left + (value - min) * width / (max - min);
    }}

    function mapY(value, min, max, top, height) {{
      return top + height - (value - min) * height / (max - min);
    }}

    function seriesPath(data, xMin, xMax, yMin, yMax, left, top, width, height) {{
      return data.map((point, index) => {{
        const x = mapX(point.x, xMin, xMax, left, width);
        const y = mapY(point.y, yMin, yMax, top, height);
        return `${{index === 0 ? "M" : "L"}}${{svgPoint(x, y)}}`;
      }}).join(" ");
    }}

    function line(x1, y1, x2, y2, color, dash = "") {{
      return `<line x1="${{x1}}" y1="${{y1}}" x2="${{x2}}" y2="${{y2}}" stroke="${{color}}" stroke-width="1.2"${{dash ? ` stroke-dasharray="${{dash}}"` : ""}} />`;
    }}

    function text(x, y, content, color = COLORS.muted, anchor = "start", size = 13, weight = 500) {{
      return `<text x="${{x}}" y="${{y}}" fill="${{color}}" text-anchor="${{anchor}}" font-size="${{size}}" font-weight="${{weight}}">${{content}}</text>`;
    }}

    function buildLayout() {{
      document.getElementById("chips").innerHTML = CONFIG.chips.map((chip) => `<span class="chip">${{chip}}</span>`).join("");
      document.getElementById("explainPoints").innerHTML = CONFIG.explainPoints.map((point) => `<li>${{point}}</li>`).join("");
      document.getElementById("leftTitle").textContent = CONFIG.leftTitle;
      document.getElementById("leftIntro").textContent = CONFIG.leftIntro;
      document.getElementById("rightTitle").textContent = CONFIG.rightTitle;
      document.getElementById("rightIntro").textContent = CONFIG.rightIntro;
      document.getElementById("formulaText").innerHTML = CONFIG.formulaText;

      document.getElementById("controls").innerHTML = CONFIG.controls.map((control) => `
        <div class="control">
          <label for="${{control.id}}">
            <span>${{control.label}}</span>
            <strong id="${{control.id}}Value"></strong>
          </label>
          <input
            id="${{control.id}}"
            type="range"
            min="${{control.min}}"
            max="${{control.max}}"
            step="${{control.step}}"
            value="${{control.value}}"
          >
          <small>${{control.hint}}</small>
        </div>
      `).join("");

      document.getElementById("readouts").innerHTML = CONFIG.readouts.map((card) => `
        <article class="card">
          <div class="label">${{card.label}}</div>
          <div class="value" id="${{card.id}}">${{card.value}}</div>
        </article>
      `).join("");

      CONFIG.controls.forEach((control) => {{
        const slider = document.getElementById(control.id);
        slider.addEventListener("input", () => {{
          STATE[control.id] = Number(slider.value);
          render();
        }});
      }});
    }}

    function updateReadouts() {{
      CONFIG.controls.forEach((control) => {{
        document.getElementById(`${{control.id}}Value`).textContent = `${{fmt(STATE[control.id], 2)}}${{control.unit}}`;
      }});

      // TODO: Replace these demo readouts with your domain values.
      document.getElementById("readoutA").textContent = fmt(STATE.speed, 2);
      document.getElementById("readoutB").textContent = fmt(STATE.ratio, 2);
      document.getElementById("readoutC").textContent = fmt(STATE.speed * STATE.ratio, 2);
      document.getElementById("readoutD").textContent = fmt(STATE.ratio / Math.max(STATE.speed, 0.001), 2);
    }}

    function renderLeftPlot() {{
      const svg = document.getElementById("leftPlot");
      const left = 58;
      const top = 24;
      const width = 520;
      const height = 252;
      const data = [];

      for (let i = 0; i <= 240; i += 1) {{
        const x = i / 40;
        data.push({{ x, y: 1 - Math.exp(-x / Math.max(STATE.speed, 0.1)) }});
      }}

      const path = seriesPath(data, 0, 6, 0, 1.12, left, top, width, height);
      svg.innerHTML = `
        <rect x="0" y="0" width="620" height="340" fill="transparent" />
        ${{line(left, top, left, top + height, COLORS.ink)}}
        ${{line(left, top + height, left + width, top + height, COLORS.ink)}}
        ${{line(left, mapY(1, 0, 1.12, top, height), left + width, mapY(1, 0, 1.12, top, height), COLORS.green, "7 6")}}
        <path d="${{path}}" fill="none" stroke="${{COLORS.blue}}" stroke-width="3.2" />
        ${{text(left + 6, top + 14, "TODO: 左图纵轴", COLORS.muted)}}
        ${{text(left + width, top + height + 36, "TODO: 左图横轴", COLORS.muted, "end")}}
      `;
    }}

    function renderRightPlot() {{
      const svg = document.getElementById("rightPlot");
      const left = 58;
      const top = 24;
      const width = 520;
      const height = 252;
      const dataA = [];
      const dataB = [];
      const omega = STATE.ratio / Math.max(STATE.speed, 0.1);

      for (let i = 0; i <= 320; i += 1) {{
        const x = i / 40;
        dataA.push({{ x, y: Math.sin(omega * x) }});
        dataB.push({{ x, y: 0.7 * Math.sin(omega * x - 0.8) }});
      }}

      const pathA = seriesPath(dataA, 0, 8, -1.25, 1.25, left, top, width, height);
      const pathB = seriesPath(dataB, 0, 8, -1.25, 1.25, left, top, width, height);
      const zeroY = mapY(0, -1.25, 1.25, top, height);

      svg.innerHTML = `
        <rect x="0" y="0" width="620" height="340" fill="transparent" />
        ${{line(left, top, left, top + height, COLORS.ink)}}
        ${{line(left, zeroY, left + width, zeroY, COLORS.ink)}}
        <path d="${{pathA}}" fill="none" stroke="${{COLORS.orange}}" stroke-width="2.3" />
        <path d="${{pathB}}" fill="none" stroke="${{COLORS.blue}}" stroke-width="3.2" />
        ${{text(left + 6, top + 14, "TODO: 右图纵轴", COLORS.muted)}}
        ${{text(left + width, top + height + 36, "TODO: 右图横轴", COLORS.muted, "end")}}
      `;
    }}

    function render() {{
      updateReadouts();
      renderLeftPlot();
      renderRightPlot();
    }}

    buildLayout();
    render();
  </script>
</body>
</html>
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a single-file interactive concept demo scaffold.")
    parser.add_argument("output", type=Path, help="Output HTML file path.")
    parser.add_argument("--title", default="概念交互演示", help="Page title.")
    parser.add_argument(
        "--summary",
        default="TODO: 用一句话写清这个概念最值钱的结论，再用滑块和双图把它讲顺。",
        help="Lead summary shown at the top of the page.",
    )
    parser.add_argument("--overwrite", action="store_true", help="Overwrite the file if it already exists.")
    return parser.parse_args()


def build_html(title: str, summary: str) -> str:
    return (
        HTML_TEMPLATE
        .replace("__TITLE__", title)
        .replace("__SUMMARY__", summary)
        .replace("{{", "{")
        .replace("}}", "}")
    )


def main() -> int:
    args = parse_args()
    output = args.output.resolve()

    if output.exists() and not args.overwrite:
        raise SystemExit(f"Refusing to overwrite existing file: {output}")

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(build_html(args.title, args.summary), encoding="utf-8", newline="\n")
    print(f"saved -> {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
