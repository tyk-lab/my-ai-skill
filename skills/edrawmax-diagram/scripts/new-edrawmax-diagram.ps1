<#
.SYNOPSIS
从 JSON 规格生成可编辑的 EdrawMax 图表和 PNG 预览。

.DESCRIPTION
基于 EdrawMax 的 empty.eddx 或用户提供的模板创建原生 .eddx 包，验证包结构、
XML、图形 ID 和连接引用后，再写入目标文件。PNG 预览用于交付前视觉检查。

.PARAMETER Spec
JSON 图表规格路径。坐标以页面左上角为原点，单位为像素；页面会按内容边界自动扩展。

.PARAMETER Output
目标 .eddx 路径。默认拒绝覆盖已有文件。

.PARAMETER Png
PNG 预览路径。省略时与 Output 同名并使用 .png 扩展名。

.PARAMETER Template
已验证的空白 .eddx 模板路径。省略时使用 EdrawMax 默认空白模板。

.PARAMETER Force
允许覆盖已存在的 .eddx 和 PNG 文件。

.PARAMETER Open
生成完成后使用 EdrawMax 打开 .eddx 文件。

.EXAMPLE
./scripts/new-edrawmax-diagram.ps1 -Spec ./diagram.json -Output ./diagram.eddx
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$Spec,

  [Parameter(Mandatory)]
  [string]$Output,

  [string]$Png = "",
  [string]$Template = "",
  [switch]$Force,
  [switch]$Open
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$InvariantCulture = [Globalization.CultureInfo]::InvariantCulture

function Get-MapValue {
  param(
    [Collections.IDictionary]$Map,
    [string]$Name,
    $Default
  )

  if ($Map.Contains($Name)) {
    return $Map[$Name]
  }

  return $Default
}

function Get-Number {
  param(
    [Collections.IDictionary]$Map,
    [string]$Name,
    [double]$Default,
    [double]$Minimum = [double]::NegativeInfinity
  )

  $value = [double](Get-MapValue -Map $Map -Name $Name -Default $Default)
  if ([double]::IsNaN($value) -or [double]::IsInfinity($value) -or $value -lt $Minimum) {
    throw "Property '$Name' must be a finite number greater than or equal to $Minimum."
  }

  return $value
}

function Format-Number {
  param([double]$Value)

  return $Value.ToString("0.###", $InvariantCulture)
}

function ConvertTo-EdrawY {
  param(
    [double]$Value,
    [double]$PageHeight
  )

  # JSON 与 PNG 使用左上原点；Edraw 页面坐标从左下向上增长。
  return $PageHeight - $Value
}

function Normalize-HexColor {
  param(
    [AllowNull()]
    [string]$Value,
    [string]$Default
  )

  $color = if ([string]::IsNullOrWhiteSpace($Value)) { $Default } else { $Value }
  if ($color -notmatch '^#[0-9a-fA-F]{6}$') {
    throw "Color must use #RRGGBB format: $color"
  }

  return $color.ToUpperInvariant()
}

function ConvertTo-EdrawColor {
  param([string]$Value)

  return "#ff$($Value.Substring(1).ToLowerInvariant())"
}

function Escape-XmlText {
  param([AllowNull()][string]$Value)

  if ($null -eq $Value) {
    return ""
  }

  return [Security.SecurityElement]::Escape($Value)
}

function Resolve-EdrawTemplate {
  param([string]$TemplatePath)

  if (-not [string]::IsNullOrWhiteSpace($TemplatePath)) {
    return [IO.Path]::GetFullPath($TemplatePath)
  }

  $defaultTemplate = 'C:\Program Files\Edrawsoft\EdrawMax\config\empty.eddx'
  if (Test-Path -LiteralPath $defaultTemplate -PathType Leaf) {
    return $defaultTemplate
  }

  return $null
}

function Assert-OutputPath {
  param(
    [string]$Path,
    [string]$Extension,
    [switch]$AllowOverwrite
  )

  if ([IO.Path]::GetExtension($Path) -ine $Extension) {
    throw "Output must use the $Extension extension: $Path"
  }

  if ((Test-Path -LiteralPath $Path) -and -not $AllowOverwrite) {
    throw "Output already exists. Pass -Force only when overwriting is intended: $Path"
  }
}

function New-TemporaryPath {
  param([string]$TargetPath)

  $directory = Split-Path -Parent $TargetPath
  if (-not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
  }

  return Join-Path $directory (".{0}.{1}.tmp" -f [IO.Path]::GetFileName($TargetPath), [guid]::NewGuid().ToString("N"))
}

function ConvertTo-DiagramModel {
  param([Collections.IDictionary]$Data)

  $pageData = Get-MapValue -Map $Data -Name "page" -Default @{}
  if ($pageData -isnot [Collections.IDictionary]) {
    throw "Property 'page' must be an object."
  }

  $minimumPageWidth = Get-Number -Map $pageData -Name "width" -Default 320 -Minimum 320
  $minimumPageHeight = Get-Number -Map $pageData -Name "height" -Default 240 -Minimum 240
  $pagePadding = Get-Number -Map $pageData -Name "padding" -Default 60 -Minimum 0
  $background = Normalize-HexColor -Value (Get-MapValue -Map $pageData -Name "background" -Default "#FFFFFF") -Default "#FFFFFF"
  $title = [string](Get-MapValue -Map $Data -Name "title" -Default "")
  $nodesData = @(Get-MapValue -Map $Data -Name "nodes" -Default @())
  $groupsData = @(Get-MapValue -Map $Data -Name "groups" -Default @())
  $edgesData = @(Get-MapValue -Map $Data -Name "edges" -Default @())

  if ($nodesData.Count -eq 0) {
    throw "At least one node is required."
  }

  $nodeIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $nodes = [Collections.Generic.List[object]]::new()
  $nativeId = 200

  foreach ($nodeData in $nodesData) {
    if ($nodeData -isnot [Collections.IDictionary]) {
      throw "Every node must be an object."
    }

    $id = [string](Get-MapValue -Map $nodeData -Name "id" -Default "")
    if ([string]::IsNullOrWhiteSpace($id) -or -not $nodeIds.Add($id)) {
      throw "Every node requires a unique non-empty id. Invalid id: '$id'"
    }

    $shape = ([string](Get-MapValue -Map $nodeData -Name "shape" -Default "rectangle")).ToLowerInvariant()
    if ($shape -notin @("rectangle", "rounded", "diamond", "ellipse", "text")) {
      throw "Unsupported shape '$shape' for node '$id'."
    }

    $x = Get-Number -Map $nodeData -Name "x" -Default 0 -Minimum 0
    $y = Get-Number -Map $nodeData -Name "y" -Default 0 -Minimum 0
    $width = Get-Number -Map $nodeData -Name "width" -Default 180 -Minimum 20
    $height = Get-Number -Map $nodeData -Name "height" -Default 70 -Minimum 20
    $nodes.Add([pscustomobject]@{
        Id = $id
        NativeId = $nativeId
        Text = [string](Get-MapValue -Map $nodeData -Name "text" -Default $id)
        Shape = $shape
        X = $x
        Y = $y
        Width = $width
        Height = $height
        Fill = Normalize-HexColor -Value (Get-MapValue -Map $nodeData -Name "fill" -Default "#FFFFFF") -Default "#FFFFFF"
        Stroke = Normalize-HexColor -Value (Get-MapValue -Map $nodeData -Name "stroke" -Default "#334155") -Default "#334155"
        TextColor = Normalize-HexColor -Value (Get-MapValue -Map $nodeData -Name "textColor" -Default "#0F172A") -Default "#0F172A"
        FontSize = Get-Number -Map $nodeData -Name "fontSize" -Default 15 -Minimum 6
        StrokeWidth = Get-Number -Map $nodeData -Name "strokeWidth" -Default 2 -Minimum 0.5
      })
    $nativeId++
  }

  $groups = [Collections.Generic.List[object]]::new()
  foreach ($groupData in $groupsData) {
    if ($groupData -isnot [Collections.IDictionary]) {
      throw "Every group must be an object."
    }

    $id = [string](Get-MapValue -Map $groupData -Name "id" -Default "")
    if ([string]::IsNullOrWhiteSpace($id)) {
      throw "Every group requires a non-empty id."
    }

    $x = Get-Number -Map $groupData -Name "x" -Default 0 -Minimum 0
    $y = Get-Number -Map $groupData -Name "y" -Default 0 -Minimum 0
    $width = Get-Number -Map $groupData -Name "width" -Default 300 -Minimum 40
    $height = Get-Number -Map $groupData -Name "height" -Default 200 -Minimum 40
    $groups.Add([pscustomobject]@{
        Id = $id
        NativeId = $nativeId
        Text = [string](Get-MapValue -Map $groupData -Name "text" -Default $id)
        X = $x
        Y = $y
        Width = $width
        Height = $height
        Fill = Normalize-HexColor -Value (Get-MapValue -Map $groupData -Name "fill" -Default "#F8FAFC") -Default "#F8FAFC"
        Stroke = Normalize-HexColor -Value (Get-MapValue -Map $groupData -Name "stroke" -Default "#94A3B8") -Default "#94A3B8"
        TextColor = Normalize-HexColor -Value (Get-MapValue -Map $groupData -Name "textColor" -Default "#475569") -Default "#475569"
        FontSize = Get-Number -Map $groupData -Name "fontSize" -Default 13 -Minimum 6
      })
    $nativeId++
  }

  $nodeMap = @{}
  foreach ($node in $nodes) {
    $nodeMap[$node.Id] = $node
  }

  $edgeIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $edges = [Collections.Generic.List[object]]::new()
  foreach ($edgeData in $edgesData) {
    if ($edgeData -isnot [Collections.IDictionary]) {
      throw "Every edge must be an object."
    }

    $id = [string](Get-MapValue -Map $edgeData -Name "id" -Default "edge-$nativeId")
    if (-not $edgeIds.Add($id)) {
      throw "Every edge requires a unique id. Duplicate id: '$id'"
    }

    $fromId = [string](Get-MapValue -Map $edgeData -Name "from" -Default "")
    $toId = [string](Get-MapValue -Map $edgeData -Name "to" -Default "")
    if (-not $nodeMap.ContainsKey($fromId) -or -not $nodeMap.ContainsKey($toId)) {
      throw "Edge '$id' references an unknown node."
    }

    $style = ([string](Get-MapValue -Map $edgeData -Name "style" -Default "orthogonal")).ToLowerInvariant()
    if ($style -notin @("straight", "orthogonal")) {
      throw "Unsupported edge style '$style' for edge '$id'."
    }

    $points = [Collections.Generic.List[object]]::new()
    foreach ($pointData in @(Get-MapValue -Map $edgeData -Name "points" -Default @())) {
      if ($pointData -isnot [Collections.IDictionary]) {
        throw "Every point on edge '$id' must be an object."
      }

      $point = [pscustomobject]@{
        X = Get-Number -Map $pointData -Name "x" -Default 0 -Minimum 0
        Y = Get-Number -Map $pointData -Name "y" -Default 0 -Minimum 0
      }
      $points.Add($point)
    }

    $fromSide = ([string](Get-MapValue -Map $edgeData -Name "fromSide" -Default "auto")).ToLowerInvariant()
    $toSide = ([string](Get-MapValue -Map $edgeData -Name "toSide" -Default "auto")).ToLowerInvariant()
    foreach ($side in @($fromSide, $toSide)) {
      if ($side -notin @("auto", "top", "right", "bottom", "left")) {
        throw "Unsupported connection side '$side' for edge '$id'."
      }
    }

    $edges.Add([pscustomobject]@{
        Id = $id
        NativeId = $nativeId
        From = $nodeMap[$fromId]
        To = $nodeMap[$toId]
        Text = [string](Get-MapValue -Map $edgeData -Name "label" -Default "")
        Style = $style
        FromSide = $fromSide
        ToSide = $toSide
        Points = $points
        Color = Normalize-HexColor -Value (Get-MapValue -Map $edgeData -Name "color" -Default "#475569") -Default "#475569"
        TextColor = Normalize-HexColor -Value (Get-MapValue -Map $edgeData -Name "textColor" -Default "#334155") -Default "#334155"
        FontSize = Get-Number -Map $edgeData -Name "fontSize" -Default 11 -Minimum 6
        StrokeWidth = Get-Number -Map $edgeData -Name "strokeWidth" -Default 2 -Minimum 0.5
      })
    $nativeId++
  }

  $contentRight = 0.0
  $contentBottom = 0.0
  foreach ($item in @($nodes) + @($groups)) {
    $contentRight = [Math]::Max($contentRight, $item.X + $item.Width)
    $contentBottom = [Math]::Max($contentBottom, $item.Y + $item.Height)
  }
  foreach ($edge in $edges) {
    foreach ($point in $edge.Points) {
      $contentRight = [Math]::Max($contentRight, $point.X)
      $contentBottom = [Math]::Max($contentBottom, $point.Y)
    }
  }

  $pageWidth = [Math]::Max($minimumPageWidth, [Math]::Ceiling($contentRight + $pagePadding))
  $pageHeight = [Math]::Max($minimumPageHeight, [Math]::Ceiling($contentBottom + $pagePadding))

  return [pscustomobject]@{
    Title = $title
    Width = $pageWidth
    Height = $pageHeight
    Background = $background
    Nodes = $nodes
    Groups = $groups
    Edges = $edges
  }
}

function Get-ConnectionPoint {
  param(
    $Node,
    [string]$Side,
    $OtherNode
  )

  $centerX = $Node.X + ($Node.Width / 2)
  $centerY = $Node.Y + ($Node.Height / 2)
  if ($Side -eq "auto") {
    $otherX = $OtherNode.X + ($OtherNode.Width / 2)
    $otherY = $OtherNode.Y + ($OtherNode.Height / 2)
    $deltaX = $otherX - $centerX
    $deltaY = $otherY - $centerY
    if ([Math]::Abs($deltaX) -ge [Math]::Abs($deltaY)) {
      $Side = if ($deltaX -ge 0) { "right" } else { "left" }
    }
    else {
      $Side = if ($deltaY -ge 0) { "bottom" } else { "top" }
    }
  }

  switch ($Side) {
    "top" { return [pscustomobject]@{ X = $centerX; Y = $Node.Y } }
    "right" { return [pscustomobject]@{ X = $Node.X + $Node.Width; Y = $centerY } }
    "bottom" { return [pscustomobject]@{ X = $centerX; Y = $Node.Y + $Node.Height } }
    "left" { return [pscustomobject]@{ X = $Node.X; Y = $centerY } }
  }
}

function Get-EdgePath {
  param($Edge)

  $start = Get-ConnectionPoint -Node $Edge.From -Side $Edge.FromSide -OtherNode $Edge.To
  $end = Get-ConnectionPoint -Node $Edge.To -Side $Edge.ToSide -OtherNode $Edge.From
  $points = [Collections.Generic.List[object]]::new()
  $points.Add($start)

  if ($Edge.Points.Count -gt 0) {
    foreach ($point in $Edge.Points) {
      $points.Add($point)
    }
  }
  elseif ($Edge.Style -eq "orthogonal" -and $start.X -ne $end.X -and $start.Y -ne $end.Y) {
    $horizontalStart = $Edge.FromSide -in @("left", "right") -or ($Edge.FromSide -eq "auto" -and [Math]::Abs($end.X - $start.X) -ge [Math]::Abs($end.Y - $start.Y))
    if ($horizontalStart) {
      $middleX = ($start.X + $end.X) / 2
      $points.Add([pscustomobject]@{ X = $middleX; Y = $start.Y })
      $points.Add([pscustomobject]@{ X = $middleX; Y = $end.Y })
    }
    else {
      $middleY = ($start.Y + $end.Y) / 2
      $points.Add([pscustomobject]@{ X = $start.X; Y = $middleY })
      $points.Add([pscustomobject]@{ X = $end.X; Y = $middleY })
    }
  }

  $points.Add($end)
  $deduplicated = [Collections.Generic.List[object]]::new()
  foreach ($point in $points) {
    if ($deduplicated.Count -eq 0 -or $deduplicated[$deduplicated.Count - 1].X -ne $point.X -or $deduplicated[$deduplicated.Count - 1].Y -ne $point.Y) {
      $deduplicated.Add($point)
    }
  }

  return $deduplicated
}

function New-TextXml {
  param(
    [string]$Text,
    [double]$Width,
    [double]$Height,
    [string]$Color,
    [double]$FontSize,
    [ValidateSet("Center", "Top")]
    [string]$VerticalAlignment = "Center"
  )

  $widthValue = Format-Number $Width
  $heightValue = Format-Number $Height
  $centerX = Format-Number ($Width / 2)
  $centerY = Format-Number ($Height / 2)
  $safeText = Escape-XmlText $Text
  $edrawColor = ConvertTo-EdrawColor $Color
  $alignment = if ($VerticalAlignment -eq "Top") { "Top" } else { "Center" }

  return @"
<Texts><Text ID="1" Name="T1" ExtendMode="0"><Transform><Width V="$widthValue"/><Height V="$heightValue"/><Angle V="0"/><GPinX V="$centerX"/><GPinY V="$centerY"/><LocPinX V="$centerX"/><LocPinY V="$centerY"/><TxtField V="" U="STR"/></Transform><TextBlock VAlign="$alignment" TextFormatMask="0"><Color V="$edrawColor"/><Character IX="0" Family="Microsoft YaHei" Size="$(Format-Number $FontSize)" Style="1" Color="$($Color.ToLowerInvariant())"/><Paragraph IX="0" SpLine="100" Align="4" IndFirst="0" IndLeft="0" IndRight="0" SpaceBefore="0" SpaceAfter="0"/><Margins Left="8" Right="8" Top="8" Bottom="8"/><Text><pp PX="0" CX="0"><tp CX="0">$safeText</tp></pp></Text></TextBlock></Text></Texts>
"@
}

function New-ConnectionPointsXml {
  param(
    [double]$Width,
    [double]$Height
  )

  $widthValue = Format-Number $Width
  $heightValue = Format-Number $Height
  $halfWidth = Format-Number ($Width / 2)
  $halfHeight = Format-Number ($Height / 2)
  return "<CPoints><CPoint Name=`"Pt1`" ID=`"1`" Type=`"0`"><X V=`"0`"/><Y V=`"$halfHeight`"/></CPoint><CPoint Name=`"Pt2`" ID=`"2`" Type=`"0`"><X V=`"$halfWidth`"/><Y V=`"$heightValue`"/></CPoint><CPoint Name=`"Pt3`" ID=`"3`" Type=`"0`"><X V=`"$widthValue`"/><Y V=`"$halfHeight`"/></CPoint><CPoint Name=`"Pt4`" ID=`"4`" Type=`"0`"><X V=`"$halfWidth`"/><Y V=`"0`"/></CPoint></CPoints>"
}

function New-GeometryXml {
  param(
    [string]$Shape,
    [double]$Width,
    [double]$Height
  )

  $widthValue = Format-Number $Width
  $heightValue = Format-Number $Height
  $halfWidth = Format-Number ($Width / 2)
  $halfHeight = Format-Number ($Height / 2)

  switch ($Shape) {
    "diamond" {
      return "<Geometries><Geometry><NoFill V=`"0`"/><NoLine V=`"0`"/><Closed V=`"1`"/><NoShow V=`"0`"/><NoSnap V=`"1`"/><MoveTo><X V=`"$halfWidth`"/><Y V=`"$heightValue`"/></MoveTo><LineTo><X V=`"$widthValue`"/><Y V=`"$halfHeight`"/></LineTo><LineTo><X V=`"$halfWidth`"/><Y V=`"0`"/></LineTo><LineTo><X V=`"0`"/><Y V=`"$halfHeight`"/></LineTo><LineTo><X V=`"$halfWidth`"/><Y V=`"$heightValue`"/></LineTo></Geometry></Geometries>"
    }
    "rounded" {
      $radius = [Math]::Min($Width / 2, $Height / 2)
      $right = Format-Number ($Width - $radius)
      $radiusValue = Format-Number $radius
      return "<Geometries><Geometry><NoFill V=`"0`"/><NoLine V=`"0`"/><Closed V=`"1`"/><NoShow V=`"0`"/><NoSnap V=`"1`"/><MoveTo><X V=`"$radiusValue`"/><Y V=`"$heightValue`"/></MoveTo><LineTo><X V=`"$right`"/><Y V=`"$heightValue`"/></LineTo><EllipseArcTo2><X V=`"$right`"/><Y V=`"$halfHeight`"/><A V=`"$radiusValue`"/><B V=`"$halfHeight`"/><C V=`"90`"/><D V=`"-180`"/></EllipseArcTo2><LineTo><X V=`"$radiusValue`"/><Y V=`"0`"/></LineTo><EllipseArcTo2><X V=`"$radiusValue`"/><Y V=`"$halfHeight`"/><A V=`"$radiusValue`"/><B V=`"$halfHeight`"/><C V=`"-90`"/><D V=`"-180`"/></EllipseArcTo2></Geometry></Geometries>"
    }
    "ellipse" {
      $xControl = Format-Number ($Width * 0.223858)
      $yControl = Format-Number ($Height * 0.223858)
      $rightControl = Format-Number ($Width - ($Width * 0.223858))
      $bottomControl = Format-Number ($Height - ($Height * 0.223858))
      return "<Geometries><Geometry><NoFill V=`"0`"/><NoLine V=`"0`"/><Closed V=`"1`"/><NoShow V=`"0`"/><NoSnap V=`"1`"/><MoveTo><X V=`"0`"/><Y V=`"$halfHeight`"/></MoveTo><CurveTo><X V=`"$halfWidth`"/><Y V=`"0`"/><A V=`"0`"/><B V=`"$yControl`"/><C V=`"$xControl`"/><D V=`"0`"/></CurveTo><CurveTo><X V=`"$widthValue`"/><Y V=`"$halfHeight`"/><A V=`"$rightControl`"/><B V=`"0`"/><C V=`"$widthValue`"/><D V=`"$yControl`"/></CurveTo><CurveTo><X V=`"$halfWidth`"/><Y V=`"$heightValue`"/><A V=`"$widthValue`"/><B V=`"$bottomControl`"/><C V=`"$rightControl`"/><D V=`"$heightValue`"/></CurveTo><CurveTo><X V=`"0`"/><Y V=`"$halfHeight`"/><A V=`"$xControl`"/><B V=`"$heightValue`"/><C V=`"0`"/><D V=`"$bottomControl`"/></CurveTo></Geometry></Geometries>"
    }
    default {
      $noFill = if ($Shape -eq "text") { "1" } else { "0" }
      $noLine = if ($Shape -eq "text") { "1" } else { "0" }
      return "<Geometries><Geometry><NoFill V=`"$noFill`"/><NoLine V=`"$noLine`"/><Closed V=`"1`"/><NoShow V=`"0`"/><NoSnap V=`"1`"/><MoveTo><X V=`"$widthValue`"/><Y V=`"$heightValue`"/></MoveTo><LineTo><X V=`"$widthValue`"/><Y V=`"0`"/></LineTo><LineTo><X V=`"0`"/><Y V=`"0`"/></LineTo><LineTo><X V=`"0`"/><Y V=`"$heightValue`"/></LineTo><LineTo><X V=`"$widthValue`"/><Y V=`"$heightValue`"/></LineTo></Geometry></Geometries>"
    }
  }
}

function New-NodeXml {
  param(
    $Node,
    [double]$PageHeight,
    [switch]$Group
  )

  $centerX = Format-Number ($Node.X + ($Node.Width / 2))
  $centerY = Format-Number (ConvertTo-EdrawY -Value ($Node.Y + ($Node.Height / 2)) -PageHeight $PageHeight)
  $widthValue = Format-Number $Node.Width
  $heightValue = Format-Number $Node.Height
  $halfWidth = Format-Number ($Node.Width / 2)
  $halfHeight = Format-Number ($Node.Height / 2)
  $shape = if ($Group) { "rectangle" } else { $Node.Shape }
  $type = if ($shape -eq "ellipse") { "Ellipse" } else { "Shape" }
  $fillType = if ($shape -eq "text") { "None" } else { "Solid" }
  $lineType = if ($shape -eq "text") { "None" } else { "Solid" }
  $linePattern = if ($Group) { "2" } else { "1" }
  $textAlignment = if ($Group) { "Top" } else { "Center" }
  $name = if ($Group) { "Container" } else { $shape }
  $safeName = Escape-XmlText $name
  $fillColor = ConvertTo-EdrawColor $Node.Fill
  $strokeColor = ConvertTo-EdrawColor $Node.Stroke
  $connectionPoints = New-ConnectionPointsXml -Width $Node.Width -Height $Node.Height
  $textXml = New-TextXml -Text $Node.Text -Width $Node.Width -Height $Node.Height -Color $Node.TextColor -FontSize $Node.FontSize -VerticalAlignment $textAlignment
  $geometry = New-GeometryXml -Shape $shape -Width $Node.Width -Height $Node.Height

  return @"
<Shape Type="$type" ID="$($Node.NativeId)" Layer="2" NameU="$safeName" Name="$safeName"><Transform><Width V="$widthValue"/><Height V="$heightValue"/><Angle V="0"/><GPinX V="$centerX"/><GPinY V="$centerY"/><LocPinX V="$halfWidth"/><LocPinY V="$halfHeight"/><FlipX V="0"/><FlipY V="0"/></Transform>$connectionPoints<Misc><ObjectType V="2"/></Misc><ShapeFormat QuickMask="51"><FillFormat Type="$fillType"><Color V="$fillColor"/></FillFormat><LineFormat><LineWeight V="$(Format-Number $Node.StrokeWidth)"/><LineCap V="Flat"/><LinePattern ID="$linePattern"/><BeginArrow ID="0" Size="4"/><EndArrow ID="0" Size="4"/><LineFill Type="$lineType"><Color V="$strokeColor"/></LineFill></LineFormat><EffectFormat><Shadow Mode="0"/></EffectFormat></ShapeFormat>$textXml$geometry</Shape>
"@
}

function New-EdgeXml {
  param(
    $Edge,
    [double]$PageHeight
  )

  $path = @(Get-EdgePath -Edge $Edge | ForEach-Object {
      [pscustomobject]@{ X = $_.X; Y = ConvertTo-EdrawY -Value $_.Y -PageHeight $PageHeight }
    })
  $start = $path[0]
  $end = $path[$path.Count - 1]
  $deltaX = $end.X - $start.X
  $deltaY = $end.Y - $start.Y
  $geometryParts = [Collections.Generic.List[string]]::new()
  $geometryParts.Add('<MoveTo><X V="0"/><Y V="0"/></MoveTo>')
  for ($index = 1; $index -lt $path.Count; $index++) {
    $relativeX = Format-Number ($path[$index].X - $start.X)
    $relativeY = Format-Number ($path[$index].Y - $start.Y)
    $geometryParts.Add("<LineTo><X V=`"$relativeX`"/><Y V=`"$relativeY`"/></LineTo>")
  }

  $textXml = if ([string]::IsNullOrWhiteSpace($Edge.Text)) {
    ""
  }
  else {
    New-TextXml -Text $Edge.Text -Width ([Math]::Max(60, [Math]::Abs($deltaX))) -Height 28 -Color $Edge.TextColor -FontSize $Edge.FontSize
  }
  $color = ConvertTo-EdrawColor $Edge.Color

  return @"
<Shape Type="ConnectLine" ID="$($Edge.NativeId)" Layer="2" NameU="ConnectLine" Name="ConnectLine"><ConPoints><BeginX V="$(Format-Number $start.X)" F="AUTOBEGINPNT(BeginTag,EndTag)"/><BeginY V="$(Format-Number $start.Y)" F="AUTOBEGINPNT(BeginTag,EndTag)"/><EndX V="$(Format-Number $end.X)" F="AUTOENDPNT(BeginTag,EndTag)"/><EndY V="$(Format-Number $end.Y)" F="AUTOENDPNT(BeginTag,EndTag)"/></ConPoints><Transform><Width V="$(Format-Number $deltaX)" F="EndX-BeginX"/><Height V="$(Format-Number $deltaY)" F="EndY-BeginY"/><Angle V="0" F="GUARD(0)"/><GPinX V="$(Format-Number (($start.X + $end.X) / 2))" F="(BeginX+EndX)*0.5"/><GPinY V="$(Format-Number (($start.Y + $end.Y) / 2))" F="(BeginY+EndY)*0.5"/><LocPinX V="$(Format-Number ($deltaX / 2))"/><LocPinY V="$(Format-Number ($deltaY / 2))"/><FlipX V="0"/><FlipY V="0"/><BeginTag V="0" F="Shape$($Edge.From.NativeId).XTrans"/><EndTag V="0" F="Shape$($Edge.To.NativeId).XTrans"/></Transform><Misc/><ShapeFormat QuickMask="99"><FillFormat Type="None"/><LineFormat><LineWeight V="$(Format-Number $Edge.StrokeWidth)"/><LineCap V="Flat"/><LinePattern ID="1"/><BeginArrow ID="0" Size="3"/><EndArrow ID="4" Size="3"/><LineFill Type="Solid"><Color V="$color"/></LineFill></LineFormat><EffectFormat><Shadow Mode="0"/></EffectFormat></ShapeFormat>$textXml<Geometries><Geometry><NoFill V="1"/><NoLine V="0"/><Closed V="0"/><NoShow V="0"/><NoSnap V="1"/>$([string]::Join('', $geometryParts))</Geometry></Geometries><ConnectorLayout Relayout="FALSE" IgnoreJump="FALSE" Style="2"/></Shape>
"@
}

function ConvertTo-XmlString {
  param([Xml.XmlDocument]$Document)

  $settings = [Xml.XmlWriterSettings]::new()
  $settings.Encoding = [Text.UTF8Encoding]::new($false)
  $settings.Indent = $true
  $settings.NewLineChars = "`n"
  $settings.NewLineHandling = [Xml.NewLineHandling]::Replace
  $builder = [Text.StringBuilder]::new()
  $writer = [Xml.XmlWriter]::Create($builder, $settings)
  try {
    $Document.Save($writer)
  }
  finally {
    $writer.Dispose()
  }

  return $builder.ToString()
}

function New-PageXml {
  param(
    [string]$TemplateXml,
    $Model
  )

  $document = [Xml.XmlDocument]::new()
  $document.PreserveWhitespace = $true
  $document.LoadXml($TemplateXml)
  $document.Page.SetAttribute("Name", $(if ([string]::IsNullOrWhiteSpace($Model.Title)) { "Page-1" } else { $Model.Title }))
  foreach ($property in @("Width", "PageBreakWidth")) {
    $document.Page.PageProps.$property.SetAttribute("V", (Format-Number $Model.Width))
  }
  foreach ($property in @("Height", "PageBreakHeight")) {
    $document.Page.PageProps.$property.SetAttribute("V", (Format-Number $Model.Height))
  }
  $document.Page.FillFormat.SetAttribute("Type", "Solid")
  $background = $document.Page.FillFormat.SelectSingleNode("Color")
  if ($null -eq $background) {
    $background = $document.CreateElement("Color")
    $document.Page.FillFormat.AppendChild($background) | Out-Null
  }
  $background.SetAttribute("V", (ConvertTo-EdrawColor $Model.Background))

  $parts = [Collections.Generic.List[string]]::new()
  foreach ($group in $Model.Groups) {
    $group | Add-Member -NotePropertyName Shape -NotePropertyValue "rectangle" -Force
    $group | Add-Member -NotePropertyName StrokeWidth -NotePropertyValue 1.5 -Force
    $parts.Add((New-NodeXml -Node $group -PageHeight $Model.Height -Group))
  }
  foreach ($edge in $Model.Edges) {
    $parts.Add((New-EdgeXml -Edge $edge -PageHeight $Model.Height))
  }
  foreach ($node in $Model.Nodes) {
    $parts.Add((New-NodeXml -Node $node -PageHeight $Model.Height))
  }

  $fragment = $document.CreateDocumentFragment()
  $fragment.InnerXml = [string]::Join("`n", $parts)
  $document.Page.AppendChild($fragment) | Out-Null
  return ConvertTo-XmlString -Document $document
}

function New-DocumentXml {
  param([string]$TemplateXml)

  $document = [Xml.XmlDocument]::new()
  $document.PreserveWhitespace = $true
  $document.LoadXml($TemplateXml)
  $document.Document.SetAttribute("DocGuid", [guid]::NewGuid().ToString("B"))
  if ($null -ne $document.Document.Creator) {
    $document.Document.Creator.SetAttribute("V", "Codex")
  }
  if ($null -ne $document.Document.Modifier) {
    $document.Document.Modifier.SetAttribute("V", "Codex")
  }
  return ConvertTo-XmlString -Document $document
}

function Read-ZipEntryText {
  param(
    [IO.Compression.ZipArchive]$Archive,
    [string]$Name
  )

  $entry = $Archive.GetEntry($Name)
  if ($null -eq $entry) {
    throw "Template is missing required entry: $Name"
  }

  $reader = [IO.StreamReader]::new($entry.Open())
  try {
    return $reader.ReadToEnd()
  }
  finally {
    $reader.Dispose()
  }
}

function Write-ZipEntryText {
  param(
    [IO.Compression.ZipArchive]$Archive,
    [string]$Name,
    [string]$Content
  )

  $entry = $Archive.CreateEntry($Name, [IO.Compression.CompressionLevel]::Optimal)
  $writer = [IO.StreamWriter]::new($entry.Open(), [Text.UTF8Encoding]::new($false))
  try {
    $writer.Write($Content)
  }
  finally {
    $writer.Dispose()
  }
}

function New-EdrawPackage {
  param(
    [string]$TemplatePath,
    [string]$TargetPath,
    $Model
  )

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $templateZip = $null
  $targetZip = $null
  try {
    $templateZip = [IO.Compression.ZipFile]::OpenRead($TemplatePath)
    $documentXml = New-DocumentXml -TemplateXml (Read-ZipEntryText -Archive $templateZip -Name "document.xml")
    $pageXml = New-PageXml -TemplateXml (Read-ZipEntryText -Archive $templateZip -Name "pages/page1.xml") -Model $Model
    $targetZip = [IO.Compression.ZipFile]::Open($TargetPath, [IO.Compression.ZipArchiveMode]::Create)

    foreach ($entry in $templateZip.Entries) {
      if ($entry.FullName -eq "document.xml") {
        Write-ZipEntryText -Archive $targetZip -Name $entry.FullName -Content $documentXml
      }
      elseif ($entry.FullName -eq "pages/page1.xml") {
        Write-ZipEntryText -Archive $targetZip -Name $entry.FullName -Content $pageXml
      }
      else {
        $targetEntry = $targetZip.CreateEntry($entry.FullName, [IO.Compression.CompressionLevel]::Optimal)
        $sourceStream = $entry.Open()
        $targetStream = $targetEntry.Open()
        try {
          $sourceStream.CopyTo($targetStream)
        }
        finally {
          $targetStream.Dispose()
          $sourceStream.Dispose()
        }
      }
    }
  }
  finally {
    if ($null -ne $targetZip) { $targetZip.Dispose() }
    if ($null -ne $templateZip) { $templateZip.Dispose() }
  }
}

function Assert-EdrawPackage {
  param([string]$Path)

  $zip = [IO.Compression.ZipFile]::OpenRead($Path)
  try {
    foreach ($name in @("document.xml", "pages/page1.xml", "rels/_rels.xml", "rels/page1_rels.xml", "theme.xml")) {
      if ($null -eq $zip.GetEntry($name)) {
        throw "Generated package is missing required entry: $name"
      }
    }

    [xml]$documentXml = Read-ZipEntryText -Archive $zip -Name "document.xml"
    [xml]$pageXml = Read-ZipEntryText -Archive $zip -Name "pages/page1.xml"
    $shapeIds = @($pageXml.Page.Shape | ForEach-Object { [string]$_.ID })
    if (($shapeIds | Sort-Object -Unique).Count -ne $shapeIds.Count) {
      throw "Generated package contains duplicate shape IDs."
    }

    $shapeIdSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($shapeId in $shapeIds) {
      $shapeIdSet.Add($shapeId) | Out-Null
    }
    foreach ($edge in @($pageXml.Page.Shape | Where-Object { $_.Type -eq "ConnectLine" })) {
      foreach ($formula in @([string]$edge.Transform.BeginTag.F, [string]$edge.Transform.EndTag.F)) {
        if ($formula -notmatch '^Shape([0-9]+)\.XTrans$' -or -not $shapeIdSet.Contains($Matches[1])) {
          throw "Connector $($edge.ID) contains an invalid shape reference: $formula"
        }
      }
    }
  }
  finally {
    $zip.Dispose()
  }
}

function New-RoundedRectanglePath {
  param(
    [Drawing.RectangleF]$Rectangle,
    [single]$Radius
  )

  $path = [Drawing.Drawing2D.GraphicsPath]::new()
  $diameter = [Math]::Min($Radius * 2, [Math]::Min($Rectangle.Width, $Rectangle.Height))
  $arc = [Drawing.RectangleF]::new($Rectangle.X, $Rectangle.Y, $diameter, $diameter)
  $path.AddArc($arc, 180, 90)
  $arc.X = $Rectangle.Right - $diameter
  $path.AddArc($arc, 270, 90)
  $arc.Y = $Rectangle.Bottom - $diameter
  $path.AddArc($arc, 0, 90)
  $arc.X = $Rectangle.X
  $path.AddArc($arc, 90, 90)
  $path.CloseFigure()
  return $path
}

function Get-DrawingColor {
  param([string]$Value)

  return [Drawing.ColorTranslator]::FromHtml($Value)
}

function Draw-CenteredText {
  param(
    [Drawing.Graphics]$Graphics,
    [string]$Text,
    [Drawing.RectangleF]$Rectangle,
    [string]$Color,
    [single]$FontSize,
    [switch]$Top
  )

  $font = [Drawing.Font]::new("Microsoft YaHei", $FontSize, [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
  $brush = [Drawing.SolidBrush]::new((Get-DrawingColor $Color))
  $format = [Drawing.StringFormat]::new()
  $format.Alignment = [Drawing.StringAlignment]::Center
  $format.LineAlignment = if ($Top) { [Drawing.StringAlignment]::Near } else { [Drawing.StringAlignment]::Center }
  $format.Trimming = [Drawing.StringTrimming]::EllipsisWord
  try {
    $Graphics.DrawString($Text, $font, $brush, $Rectangle, $format)
  }
  finally {
    $format.Dispose()
    $brush.Dispose()
    $font.Dispose()
  }
}

function Draw-Node {
  param(
    [Drawing.Graphics]$Graphics,
    $Node,
    [switch]$Group
  )

  $rectangle = [Drawing.RectangleF]::new([single]$Node.X, [single]$Node.Y, [single]$Node.Width, [single]$Node.Height)
  $fillBrush = [Drawing.SolidBrush]::new((Get-DrawingColor $Node.Fill))
  $pen = [Drawing.Pen]::new((Get-DrawingColor $Node.Stroke), [single]$Node.StrokeWidth)
  if ($Group) {
    $pen.DashStyle = [Drawing.Drawing2D.DashStyle]::Dash
  }

  try {
    if ($Group -or $Node.Shape -eq "rectangle") {
      $Graphics.FillRectangle($fillBrush, $rectangle)
      $Graphics.DrawRectangle($pen, $rectangle.X, $rectangle.Y, $rectangle.Width, $rectangle.Height)
    }
    elseif ($Node.Shape -eq "rounded") {
      $path = New-RoundedRectanglePath -Rectangle $rectangle -Radius ([single]([Math]::Min(18, $Node.Height / 2)))
      try {
        $Graphics.FillPath($fillBrush, $path)
        $Graphics.DrawPath($pen, $path)
      }
      finally {
        $path.Dispose()
      }
    }
    elseif ($Node.Shape -eq "diamond") {
      [Drawing.PointF[]]$points = @(
        [Drawing.PointF]::new($rectangle.X + ($rectangle.Width / 2), $rectangle.Y),
        [Drawing.PointF]::new($rectangle.Right, $rectangle.Y + ($rectangle.Height / 2)),
        [Drawing.PointF]::new($rectangle.X + ($rectangle.Width / 2), $rectangle.Bottom),
        [Drawing.PointF]::new($rectangle.X, $rectangle.Y + ($rectangle.Height / 2))
      )
      $Graphics.FillPolygon($fillBrush, $points)
      $Graphics.DrawPolygon($pen, $points)
    }
    elseif ($Node.Shape -eq "ellipse") {
      $Graphics.FillEllipse($fillBrush, $rectangle)
      $Graphics.DrawEllipse($pen, $rectangle)
    }

    $textRectangle = if ($Group) {
      [Drawing.RectangleF]::new($rectangle.X + 10, $rectangle.Y + 8, $rectangle.Width - 20, 28)
    }
    else {
      [Drawing.RectangleF]::new($rectangle.X + 8, $rectangle.Y + 6, $rectangle.Width - 16, $rectangle.Height - 12)
    }
    Draw-CenteredText -Graphics $Graphics -Text $Node.Text -Rectangle $textRectangle -Color $Node.TextColor -FontSize ([single]$Node.FontSize) -Top:$Group
  }
  finally {
    $pen.Dispose()
    $fillBrush.Dispose()
  }
}

function Get-PathMidpoint {
  param($Path)

  $totalLength = 0.0
  $segments = [Collections.Generic.List[object]]::new()
  for ($index = 1; $index -lt $Path.Count; $index++) {
    $dx = $Path[$index].X - $Path[$index - 1].X
    $dy = $Path[$index].Y - $Path[$index - 1].Y
    $length = [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
    $segments.Add([pscustomobject]@{ Start = $Path[$index - 1]; End = $Path[$index]; Length = $length })
    $totalLength += $length
  }

  $target = $totalLength / 2
  $travelled = 0.0
  foreach ($segment in $segments) {
    if ($travelled + $segment.Length -ge $target) {
      $ratio = if ($segment.Length -eq 0) { 0 } else { ($target - $travelled) / $segment.Length }
      return [pscustomobject]@{
        X = $segment.Start.X + (($segment.End.X - $segment.Start.X) * $ratio)
        Y = $segment.Start.Y + (($segment.End.Y - $segment.Start.Y) * $ratio)
      }
    }
    $travelled += $segment.Length
  }

  return $Path[0]
}

function Draw-Edge {
  param(
    [Drawing.Graphics]$Graphics,
    $Edge
  )

  $path = Get-EdgePath -Edge $Edge
  [Drawing.PointF[]]$points = @($path | ForEach-Object { [Drawing.PointF]::new([single]$_.X, [single]$_.Y) })
  $pen = [Drawing.Pen]::new((Get-DrawingColor $Edge.Color), [single]$Edge.StrokeWidth)
  $arrow = [Drawing.Drawing2D.AdjustableArrowCap]::new(4, 5, $true)
  $pen.CustomEndCap = $arrow
  $pen.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
  try {
    if ($points.Count -ge 2) {
      $Graphics.DrawLines($pen, $points)
    }
  }
  finally {
    $pen.Dispose()
    $arrow.Dispose()
  }

  if (-not [string]::IsNullOrWhiteSpace($Edge.Text)) {
    $midpoint = Get-PathMidpoint -Path $path
    $labelRectangle = [Drawing.RectangleF]::new([single]($midpoint.X - 55), [single]($midpoint.Y - 24), 110, 22)
    $background = [Drawing.SolidBrush]::new([Drawing.Color]::White)
    try {
      $Graphics.FillRectangle($background, $labelRectangle)
    }
    finally {
      $background.Dispose()
    }
    Draw-CenteredText -Graphics $Graphics -Text $Edge.Text -Rectangle $labelRectangle -Color $Edge.TextColor -FontSize ([single]$Edge.FontSize)
  }
}

function New-PngPreview {
  param(
    [string]$Path,
    $Model
  )

  Add-Type -AssemblyName System.Drawing.Common
  $bitmap = [Drawing.Bitmap]::new([int][Math]::Ceiling($Model.Width), [int][Math]::Ceiling($Model.Height))
  $graphics = [Drawing.Graphics]::FromImage($bitmap)
  try {
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $graphics.Clear((Get-DrawingColor $Model.Background))
    foreach ($group in $Model.Groups) {
      $group | Add-Member -NotePropertyName Shape -NotePropertyValue "rectangle" -Force
      $group | Add-Member -NotePropertyName StrokeWidth -NotePropertyValue 1.5 -Force
      Draw-Node -Graphics $graphics -Node $group -Group
    }
    foreach ($edge in $Model.Edges) {
      Draw-Edge -Graphics $graphics -Edge $edge
    }
    foreach ($node in $Model.Nodes) {
      Draw-Node -Graphics $graphics -Node $node
    }
    if (-not [string]::IsNullOrWhiteSpace($Model.Title)) {
      $titleRectangle = [Drawing.RectangleF]::new(30, 12, [single]($Model.Width - 60), 42)
      Draw-CenteredText -Graphics $graphics -Text $Model.Title -Rectangle $titleRectangle -Color "#0F172A" -FontSize 22
    }

    $bitmap.Save($Path, [Drawing.Imaging.ImageFormat]::Png)
  }
  finally {
    $graphics.Dispose()
    $bitmap.Dispose()
  }
}

function Assert-Png {
  param(
    [string]$Path,
    $Model
  )

  $image = [Drawing.Image]::FromFile($Path)
  try {
    if ($image.Width -ne [int][Math]::Ceiling($Model.Width) -or $image.Height -ne [int][Math]::Ceiling($Model.Height)) {
      throw "PNG dimensions do not match the diagram page."
    }
  }
  finally {
    $image.Dispose()
  }
}

$specPath = [IO.Path]::GetFullPath($Spec)
if (-not (Test-Path -LiteralPath $specPath -PathType Leaf)) {
  throw "Spec file not found: $specPath"
}

$outputPath = [IO.Path]::GetFullPath($Output)
$pngPath = if ([string]::IsNullOrWhiteSpace($Png)) {
  [IO.Path]::ChangeExtension($outputPath, ".png")
}
else {
  [IO.Path]::GetFullPath($Png)
}
Assert-OutputPath -Path $outputPath -Extension ".eddx" -AllowOverwrite:$Force
Assert-OutputPath -Path $pngPath -Extension ".png" -AllowOverwrite:$Force

$templatePath = Resolve-EdrawTemplate -TemplatePath $Template
if ($null -eq $templatePath -or -not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
  throw "EdrawMax template not found. Pass -Template or install EdrawMax in the default location."
}

$specData = Get-Content -Raw -LiteralPath $specPath | ConvertFrom-Json -AsHashtable -Depth 32
if ($specData -isnot [Collections.IDictionary]) {
  throw "The diagram spec root must be a JSON object."
}
$model = ConvertTo-DiagramModel -Data $specData
$temporaryEddx = New-TemporaryPath -TargetPath $outputPath
$temporaryPng = New-TemporaryPath -TargetPath $pngPath

try {
  New-EdrawPackage -TemplatePath $templatePath -TargetPath $temporaryEddx -Model $model
  Assert-EdrawPackage -Path $temporaryEddx
  New-PngPreview -Path $temporaryPng -Model $model
  Assert-Png -Path $temporaryPng -Model $model

  Move-Item -LiteralPath $temporaryEddx -Destination $outputPath -Force:$Force
  Move-Item -LiteralPath $temporaryPng -Destination $pngPath -Force:$Force
}
finally {
  foreach ($temporaryPath in @($temporaryEddx, $temporaryPng)) {
    if (Test-Path -LiteralPath $temporaryPath) {
      Remove-Item -LiteralPath $temporaryPath -Force
    }
  }
}

if ($Open) {
  $command = Get-Command edrawmax -ErrorAction SilentlyContinue
  if ($null -ne $command) {
    & $command.Source $outputPath
  }
  else {
    $executable = 'C:\Program Files\Edrawsoft\EdrawMax\EdrawMax.exe'
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
      throw "EdrawMax executable not found. Files were generated successfully: $outputPath"
    }
    Start-Process -FilePath $executable -ArgumentList @($outputPath)
  }
}

[pscustomobject]@{
  Eddx = Get-Item -LiteralPath $outputPath
  Png = Get-Item -LiteralPath $pngPath
  PageWidth = $model.Width
  PageHeight = $model.Height
}
