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

## 打开与验证

```powershell
edrawmax 'C:\path\diagram.eddx'
```

命令不可用时使用完整可执行文件路径。打开前至少确认包中存在 `document.xml`、页面 XML、关系文件和主题资源；打开后检查空白画布、缺字、裁切、连接断裂和箭头方向。
