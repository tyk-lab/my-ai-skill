<#
.SYNOPSIS
从 drawio 官方仓库下载 stencil 符号库到技能内置 stencils 目录。

.DESCRIPTION
将 draw.io 官方 stencil XML 下载到技能根目录的 stencils/ 下，供
get-edrawmax-symbols.ps1 查询并嵌入 .drawio 图表。默认下载常用精选集合，
可用 -Name 指定其他库名（对应仓库 stencils 目录中的文件名，不含 .xml）。

.PARAMETER Name
要下载的库名列表，默认为常用精选集合。仓库完整列表见：
https://github.com/jgraph/drawio/tree/dev/src/main/webapp/stencils

.PARAMETER Dest
目标目录，默认 <技能根>/stencils。

.PARAMETER Force
覆盖已存在的同名文件。

.EXAMPLE
./scripts/sync-drawio-stencils.ps1

.EXAMPLE
./scripts/sync-drawio-stencils.ps1 -Name ibm,openstack,office -Force
#>
[CmdletBinding()]
param(
  [string[]]$Name = @('aws4', 'azure', 'gcp3', 'kubernetes', 'cisco19', 'networks', 'bpmn', 'flowchart'),
  [string]$Dest = (Join-Path $PSScriptRoot '..\stencils'),
  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$baseUrl = 'https://raw.githubusercontent.com/jgraph/drawio/dev/src/main/webapp/stencils'
$destFull = [IO.Path]::GetFullPath($Dest)
if (-not (Test-Path -LiteralPath $destFull)) {
  New-Item -ItemType Directory -Path $destFull -Force | Out-Null
}

$downloaded = [Collections.Generic.List[object]]::new()
foreach ($item in $Name) {
  $fileName = "$item.xml"
  $target = Join-Path $destFull $fileName
  if ((Test-Path -LiteralPath $target) -and -not $Force) {
    Write-Warning "Skipping existing file (use -Force to overwrite): $target"
    continue
  }

  $url = "$baseUrl/$fileName"
  $tempFile = Join-Path $destFull ".$fileName.$([guid]::NewGuid().ToString('N')).tmp"
  try {
    Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing
    [xml]$null = Get-Content -LiteralPath $tempFile -Raw
    Move-Item -LiteralPath $tempFile -Destination $target -Force
    $downloaded.Add([pscustomobject]@{
        Library = $item
        Path = $target
        Bytes = (Get-Item -LiteralPath $target).Length
      })
  }
  catch {
    Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
    Write-Warning "Failed to download '$item' from $url : $($_.Exception.Message)"
  }
}

if ($downloaded.Count -gt 0) {
  $downloaded
  Write-Host "Downloaded $($downloaded.Count) stencil libraries to $destFull"
}
else {
  Write-Host "No stencil libraries were downloaded."
}
