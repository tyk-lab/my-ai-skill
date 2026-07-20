# EdrawMax 原生文件

## 检测

在 Windows PowerShell 7 中先检测包装命令，再检查默认安装路径：

```powershell
$command = Get-Command edrawmax -ErrorAction SilentlyContinue
$defaultExe = 'C:\Program Files\Edrawsoft\EdrawMax\EdrawMax.exe'
```

`edrawmax` 存在或 `$defaultExe` 为文件时，视为 EdrawMax 可用。

## 生成原则

`.eddx` 是 EdrawMax 的原生 ZIP 包。优先基于本机 `C:\Program Files\Edrawsoft\EdrawMax\config\empty.eddx` 或用户提供的已验证模板生成，绝不直接修改安装目录中的模板。

执行模板驱动生成时：

1. 把模板复制到目标目录中的新文件；目标已存在时停止，除非用户明确要求覆盖。
2. 仅修改已经理解并验证过的 XML 部件；保留主题、关系、缩略图及未知条目。
3. 为节点和连接线使用唯一 ID，并正确维护连接引用。
4. 使用 UTF-8 无 BOM 写入 XML，转义用户文本，并以临时文件完成后再原子替换目标。
5. 重新打开 ZIP，解析所有修改过的 XML，再用 EdrawMax 打开做视觉检查。

如果当前任务没有可靠的 `.eddx` 写入脚本、已知模板结构或可操作的 EdrawMax UI，不要声称已生成原生图表。改用 draw.io 生成可编辑结果，并明确说明回退原因。

## 生成脚本

本技能提供模板驱动脚本：

```powershell
./scripts/new-edrawmax-diagram.ps1 `
  -Spec 'C:\path\diagram.json' `
  -Output 'C:\path\diagram.eddx' `
  -Png 'C:\path\diagram.png'
```

省略 `-Png` 时在 `.eddx` 旁生成同名 PNG。仅在用户明确允许覆盖时传入 `-Force`；
需要生成后打开 EdrawMax 时传入 `-Open`。非默认安装或定制空白模板使用 `-Template`。

JSON 根对象支持 `title`、`page`、`groups`、`nodes` 和 `edges`。页面与图形坐标均以左上角为原点，单位为像素。不要根据模板当前页尺寸压缩布局；先按内容关系安排节点，脚本会自动扩展输出页面：

```json
{
  "title": "审批流程",
  "page": { "background": "#FFFFFF", "padding": 60 },
  "groups": [
    { "id": "business", "text": "业务侧", "x": 40, "y": 100, "width": 1120, "height": 260 }
  ],
  "nodes": [
    { "id": "submit", "text": "提交", "shape": "rounded", "x": 100, "y": 180, "width": 180, "height": 70 },
    { "id": "review", "text": "通过？", "shape": "diamond", "x": 430, "y": 165, "width": 180, "height": 100 }
  ],
  "edges": [
    { "id": "submit-review", "from": "submit", "to": "review", "label": "送审", "fromSide": "right", "toSide": "left" }
  ]
}
```

- `shape` 支持 `rectangle`、`rounded`、`diamond`、`ellipse`、`text`。
- `page.width`、`page.height` 可选且仅表示最小尺寸，不是内容边界；最终页面会容纳所有节点、分组和连线拐点。
- `page.padding` 控制内容最远边界到页面右侧、底部的额外留白，默认 60；模板自身页面尺寸不会限制输出。
- 颜色使用 `#RRGGBB`；节点可设置 `fill`、`stroke`、`textColor`、`fontSize`、`strokeWidth`。
- 连线 `style` 支持 `straight`、`orthogonal`，可通过 `points` 指定拐点；连接侧支持 `auto`、`top`、`right`、`bottom`、`left`。
- 节点 ID 与连线 ID 各自唯一，连线端点必须引用已有节点；所有坐标仍须为非负数。
- 脚本生成的 PNG 是结构一致性预览，不是 EdrawMax 自身的导出结果；最终交付仍须在 EdrawMax 中打开检查。

## 打开与验证

```powershell
edrawmax 'C:\path\diagram.eddx'
```

命令不可用时使用完整可执行文件路径。打开前至少确认包中存在 `document.xml`、页面 XML、关系文件和主题资源；打开后检查空白画布、缺字、裁切、连接断裂和箭头方向。
