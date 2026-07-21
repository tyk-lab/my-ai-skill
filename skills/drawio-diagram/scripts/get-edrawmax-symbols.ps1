<#
.SYNOPSIS
列出可供 draw.io 制图使用的 mxStencil 符号，以及本机 EdrawMax 附带的 .edt 符号索引。

.DESCRIPTION
读取 EdrawMax 安装目录 config/mxStencil 下的 draw.io stencil XML（制图默认使用
该来源），以及 library 下的 .edt 原生库索引（仅作符号名称发现参考）。
用于在制图前发现合适的语义符号，避免所有节点退化成矩形。

.PARAMETER Pattern
按“来源/分类/库/符号”组合文本进行通配符筛选，默认 *。

.PARAMETER Source
edraw、mxstencil 或 all。生成 draw.io 图表时使用 mxstencil；edraw 仅用于查询
本机还装有哪些符号名称，不能直接嵌入 .drawio。

.PARAMETER LibrariesOnly
只输出库名和符号数量，不逐项输出符号。
.PARAMETER MaxResults
最多输出多少条结果，默认 100；设为 0 表示不限制。
#>
[CmdletBinding()]
param(
  [string]$EdrawRoot = 'C:\Program Files\Edrawsoft\EdrawMax',
  [string]$Pattern = '*',
  [ValidateSet('edraw', 'mxstencil', 'all')]
  [string]$Source = 'edraw',
  [switch]$LibrariesOnly,
  [ValidateRange(0, 10000)]
  [int]$MaxResults = 100
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RelativeParent {
  param(
    [string]$Root,
    [string]$Path
  )

  $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
  $parentFull = [IO.Path]::GetFullPath((Split-Path -Parent $Path))
  if (-not $parentFull.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
    return $parentFull -replace '\\', '/'
  }
  $relative = $parentFull.Substring($rootFull.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
  return $relative -replace '\\', '/'
}

function Test-SymbolMatch {
  param(
    [string]$SourceName,
    [string]$Category,
    [string]$Library,
    [string]$Symbol
  )

  return "$SourceName/$Category/$Library/$Symbol" -like $Pattern
}

$items = [Collections.Generic.List[object]]::new()

if ($Source -in @('edraw', 'all')) {
  $libraryRoot = Join-Path $EdrawRoot 'library'
  if (-not (Test-Path -LiteralPath $libraryRoot -PathType Container)) {
    throw "EdrawMax library directory was not found: $libraryRoot"
  }

  foreach ($file in Get-ChildItem -LiteralPath $libraryRoot -Recurse -File -Filter '*.edt') {
    try {
      [xml]$document = Get-Content -LiteralPath $file.FullName -Raw
    }
    catch {
      Write-Warning "Skipping unreadable Edraw library: $($file.FullName)"
      continue
    }

    $category = Get-RelativeParent -Root $libraryRoot -Path $file.FullName
    $library = [IO.Path]::GetFileNameWithoutExtension($file.Name)
    foreach ($item in @($document.Template.Items.Item)) {
      $symbol = [string]$item.NameU
      if ([string]::IsNullOrWhiteSpace($symbol)) { $symbol = [string]$item.PromptU }
      if ([string]::IsNullOrWhiteSpace($symbol)) { continue }
      if (Test-SymbolMatch -SourceName 'edraw' -Category $category -Library $library -Symbol $symbol) {
        $items.Add([pscustomobject]@{
            Source = 'edraw'
            Category = $category
            Library = $library
            Symbol = $symbol
            Path = $file.FullName
          })
      }
    }
  }
}

if ($Source -in @('mxstencil', 'all')) {
  $stencilRoots = [Collections.Generic.List[string]]::new()
  foreach ($root in @((Join-Path $EdrawRoot 'config\mxStencil'), (Join-Path $PSScriptRoot '..\stencils'))) {
    if (Test-Path -LiteralPath $root -PathType Container) {
      $stencilRoots.Add([IO.Path]::GetFullPath($root))
    }
  }
  if ($stencilRoots.Count -eq 0) {
    throw "No stencil directory found. Run scripts/sync-drawio-stencils.ps1 to download draw.io libraries, or install EdrawMax."
  }

  foreach ($stencilRoot in $stencilRoots) {
    foreach ($file in Get-ChildItem -LiteralPath $stencilRoot -Recurse -File -Filter '*.xml') {
      try {
        [xml]$document = Get-Content -LiteralPath $file.FullName -Raw
      }
      catch {
        Write-Warning "Skipping unreadable stencil: $($file.FullName)"
        continue
      }

      $category = Get-RelativeParent -Root $stencilRoot -Path $file.FullName
      $library = [IO.Path]::GetFileNameWithoutExtension($file.Name)
      foreach ($shape in @($document.SelectNodes('//shape'))) {
        $symbol = [string]$shape.GetAttribute('name')
        if ([string]::IsNullOrWhiteSpace($symbol)) { continue }
        if (Test-SymbolMatch -SourceName 'mxstencil' -Category $category -Library $library -Symbol $symbol) {
          $items.Add([pscustomobject]@{
              Source = 'mxstencil'
              Category = $category
              Library = $library
              Symbol = $symbol
              Path = $file.FullName
            })
        }
      }
    }
  }
}

$results = @(if ($LibrariesOnly) {
  $items |
    Group-Object Source, Category, Library |
    ForEach-Object {
      $first = $_.Group[0]
      [pscustomobject]@{
        Source = $first.Source
        Category = $first.Category
        Library = $first.Library
        Symbols = $_.Count
        Path = $first.Path
      }
    } |
    Sort-Object Source, Category, Library
}
else {
  $items | Sort-Object Source, Category, Library, Symbol
})

if ($MaxResults -gt 0 -and $results.Count -gt $MaxResults) {
  Write-Warning "Found $($results.Count) matches; showing the first $MaxResults. Narrow -Pattern or set -MaxResults 0 to show all."
  $results | Select-Object -First $MaxResults
}
else {
  $results
}
