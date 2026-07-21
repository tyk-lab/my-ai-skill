# MindMaster / EdrawMind

## 适用范围

用户要求 MindMaster、EdrawMind、`.emmx` 或原生可编辑思维导图时使用本流程。普通流程图、架构图和线框图不要使用 `.emmx`。

## 检测与生成

在 Windows PowerShell 7 中检测命令和默认模板，两者均存在时才视为可用：

```powershell
Get-Command mindmaster -ErrorAction SilentlyContinue
Get-ChildItem "$env:ProgramFiles\Edrawsoft\MindMaster*\Config\empty.emmx"
```

使用技能自带脚本生成中心主题和一级分支：

```powershell
./scripts/new-mindmaster-map.ps1 `
  -Title "Project Plan" `
  -Branch "Goal","Scope","Timeline","Risks" `
  -Output "C:\path\project-plan.emmx"
```

仅当用户要求覆盖时添加 `-Force`，要求生成后打开时添加 `-Open`。脚本默认从 `%ProgramFiles%\Edrawsoft\MindMaster*\Config\empty.emmx` 查找模板，也可用 `-Template` 指定经过验证的模板。

## 格式与验证

`.emmx` 是 ZIP 容器，至少应包含：

```text
document.xml
page/page.xml
rels/page_rels.xml
theme.xml
thumbnail.png
```

生成后验证：

- ZIP 可正常打开且必需条目存在。
- `document.xml`、`page/page.xml` 和关系文件均为格式正确的 XML。
- `MainIdea` 的 `SubLevel` 与一级主题 ID 一致。
- 每个 `MainTopic` 的 `Super` 指向中心主题，`ToSuper` 指向对应 `MMConnector`。
- 用户文本已 XML 转义；最终文件能由 MindMaster 打开。

当前脚本只负责中心主题和 1–12 个一级分支。需要更多分支、多级主题、图标、备注或复杂样式时，使用经过验证的 `.emmx` 模板扩展，不要假装脚本已支持这些能力。
