param(
  [string]$Title = "Mind Map",
  [string[]]$Branch = @("Research", "Plan", "Build", "Review"),
  [string]$Output = (Join-Path (Get-Location) "mindmaster-map.emmx"),
  [string]$Template = "",
  [switch]$Force,
  [switch]$Open
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Escape-XmlText {
  param([string]$Value)

  return [System.Security.SecurityElement]::Escape($Value)
}

function Get-TopicWidth {
  param(
    [string]$Text,
    [int]$Minimum,
    [int]$Maximum,
    [int]$Padding
  )

  $width = $Padding + ($Text.Length * 11)
  return [Math]::Max($Minimum, [Math]::Min($Maximum, $width))
}

function Resolve-MindMasterTemplate {
  param([string]$TemplatePath)

  if (-not [string]::IsNullOrWhiteSpace($TemplatePath)) {
    return $TemplatePath
  }

  $edrawRoot = Join-Path $env:ProgramFiles "Edrawsoft"
  if (-not (Test-Path -LiteralPath $edrawRoot)) {
    return $null
  }

  $installDir = Get-ChildItem -LiteralPath $edrawRoot -Directory -Filter "MindMaster*" |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "MindMaster.exe") } |
    Select-Object -First 1

  if ($null -eq $installDir) {
    return $null
  }

  return Join-Path $installDir.FullName "Config\empty.emmx"
}

function New-RectGeometry {
  param(
    [double]$Width,
    [double]$Height
  )

  return @"
<Geometries><Geometry Closed="1"><MoveTo><X V="0" B="1" P="0"/><Y V="0" B="2" P="0"/></MoveTo><LineTo><X V="$Width" B="1" P="1"/><Y V="0" B="2" P="0"/></LineTo><LineTo><X V="$Width" B="1" P="1"/><Y V="$Height" B="2" P="1"/></LineTo><LineTo><X V="0" B="1" P="0"/><Y V="$Height" B="2" P="1"/></LineTo><LineTo><X V="0" B="1" P="0"/><Y V="0" B="2" P="0"/></LineTo></Geometry></Geometries>
"@
}

function New-MainIdea {
  param(
    [string]$Text,
    [string]$SubLevel
  )

  $safeText = Escape-XmlText $Text
  $width = Get-TopicWidth -Text $Text -Minimum 170 -Maximum 360 -Padding 80
  $textWidth = [Math]::Max(100, $width - 40)
  $geometry = New-RectGeometry -Width $width -Height 63
  $levelData = if ($SubLevel) { "<LevelData><SubLevel V=""$SubLevel""/></LevelData>" } else { "<LevelData/>" }

  return @"
<Shape ID="101" Type="MainIdea"><Transform><Width V="$width"/><Height V="63"/><CX V="1152" B="1" P="0"/><CY V="810" B="2" P="0"/></Transform><ShapeFormat QuickMask="0"><FillFormat Type="Solid"><Color ThemeColor="3" Shade="63" V="#ff22467f" Ref="#3b71c8"/></FillFormat><LineFormat><LineWeight V="3"/><Rounding V="4"/><LineFill Type="Solid"><Color ThemeColor="3" Shade="50" V="#ff295192" Ref="#3b71c8"/></LineFill></LineFormat></ShapeFormat><Text><Transform><Width V="$textWidth"/><Height V="31"/><CX V="$($width / 2)" B="1" P="0"/><CY V="30.95" B="2" P="0"/></Transform><TextBlock TextFormatMask="0"><Color ThemeColor="1" V="#ffffffff"/><Character IX="0" Family="Microsoft YaHei" Size="18" Style="1" Color="#ffffff"/><Paragraph IX="0" Align="4" SpLine="100" IndFirst="0" IndLeft="0" IndRight="0" SpaceBefore="0" SpaceAfter="0"/><Text><pp PX="0" CX="0"><tp CX="0">$safeText</tp></pp></Text></TextBlock></Text>$levelData$geometry<ShapeStyle V="1"/><Layout><ImagePos V="0"/><FlexoStyle V="11"/><Layout V="8"/><Margins LeftMargin="18" TopMargin="14" RightMargin="18" BottomMargin="14"/></Layout></Shape>
"@
}

function New-MainTopic {
  param(
    [int]$Id,
    [int]$ConnectorId,
    [string]$Text,
    [double]$Cx,
    [double]$Cy,
    [bool]$RightSide
  )

  $safeText = Escape-XmlText $Text
  $width = Get-TopicWidth -Text $Text -Minimum 118 -Maximum 280 -Padding 58
  $textWidth = [Math]::Max(70, $width - 37)
  $layout = if ($RightSide) { "6" } else { "7" }
  $direction = if ($RightSide) { "" } else { '<LayoutDirection V="0"/>' }
  $geometry = New-RectGeometry -Width $width -Height 44

  return @"
<Shape ID="$Id" Type="MainTopic"><Transform><Width V="$width"/><Height V="44"/><CX V="$Cx" B="1" P="0"/><CY V="$Cy" B="2" P="0"/></Transform><ShapeFormat QuickMask="0"><FillFormat Type="Solid"><Color ThemeColor="7" V="#e2f5c759"/></FillFormat><LineFormat><LineWeight V="3"/><Rounding V="4"/><LineFill Type="Solid"><Color ThemeColor="7" V="#fff5c759"/></LineFill></LineFormat></ShapeFormat><Text><Transform><Width V="$textWidth"/><Height V="26"/><CX V="$($width / 2)" B="1" P="0"/><CY V="21.45" B="2" P="0"/></Transform><TextBlock TextFormatMask="0"><Color ThemeColor="2" Tint="3" V="#ff303030" Ref="#000"/><Character IX="0" Family="Microsoft YaHei" Size="14" Style="1" Color="#303030"/><Paragraph IX="0" Align="4" SpLine="100" IndFirst="0" IndLeft="0" IndRight="0" SpaceBefore="0" SpaceAfter="0"/><Text><pp PX="0" CX="0"><tp CX="0">$safeText</tp></pp></Text></TextBlock></Text><LevelData><Super V="101"/><ToSuper V="$ConnectorId"/></LevelData>$geometry<ShapeStyle V="1"/><Layout><ImagePos V="0"/><FlexoStyle V="4"/><Layout V="$layout"/>$direction<Margins LeftMargin="16" TopMargin="7" RightMargin="16" BottomMargin="7"/></Layout></Shape>
"@
}

function New-Connector {
  param(
    [int]$Id,
    [double]$BeginX,
    [double]$BeginY,
    [double]$EndX,
    [double]$EndY
  )

  $cx = ($BeginX + $EndX) / 2
  $cy = ($BeginY + $EndY) / 2
  $halfDx = ($EndX - $BeginX) / 2
  $halfDy = ($EndY - $BeginY) / 2
  $startX = -$halfDx
  $startY = -$halfDy

  return @"
<Shape ID="$Id" Type="MMConnector"><Transform><Width V="0"/><Height V="0"/><CX V="$cx" B="1" P="0"/><CY V="$cy" B="2" P="0"/></Transform><ShapeFormat QuickMask="0"><FillFormat/><LineFormat><LineWeight V="3"/><Rounding V="3"/><LineCap V="Round"/><LineFill Type="Solid"><Color ThemeColor="1" Shade="31" V="#ffd8d8d8" Ref="#ffffff"/></LineFill></LineFormat></ShapeFormat><LevelData><Super V="101"/></LevelData><Geometries><Geometry Closed="0"><MoveTo><X V="$startX" B="1" P="0"/><Y V="$startY" B="2" P="0"/></MoveTo><LineTo><X V="$halfDx" B="1" P="0"/><Y V="$halfDy" B="2" P="0"/></LineTo></Geometry></Geometries><ShapeStyle V="1"/><BeginPt X="$BeginX" Y="$BeginY"/><EndPt X="$EndX" Y="$EndY"/><MMConnector FlexoStyle="11" Thickness="0"/></Shape>
"@
}

$resolvedTemplate = Resolve-MindMasterTemplate -TemplatePath $Template
if (-not $resolvedTemplate -or -not (Test-Path -LiteralPath $resolvedTemplate)) {
  throw "MindMaster template not found. Pass -Template or install MindMaster under Program Files\Edrawsoft."
}

$branches = @($Branch | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($branches.Count -eq 0) {
  throw "At least one branch is required."
}

if ($branches.Count -gt 12) {
  throw "At most 12 branches are supported by this layout."
}

$outputPath = [IO.Path]::GetFullPath($Output)
if ([IO.Path]::GetExtension($outputPath) -ine ".emmx") {
  throw "Output must use the .emmx extension: $outputPath"
}

if ((Test-Path -LiteralPath $outputPath) -and -not $Force) {
  throw "Output already exists. Pass -Force only when overwriting is intended: $outputPath"
}

$outputDir = Split-Path -Parent $outputPath
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
  New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

$temporaryPath = Join-Path $outputDir (".{0}.{1}.tmp" -f [IO.Path]::GetFileName($outputPath), [guid]::NewGuid().ToString("N"))

$topicIds = New-Object System.Collections.Generic.List[string]
$shapes = New-Object System.Collections.Generic.List[string]

for ($i = 0; $i -lt $branches.Count; $i++) {
  $topicId = 102 + ($i * 2)
  $connectorId = $topicId + 1
  $rightSide = ($i % 2 -eq 0)
  $row = [Math]::Floor($i / 2)
  $verticalOffset = 120 + ($row * 115)
  if ($row % 2 -eq 1) {
    $verticalOffset = -$verticalOffset
  }

  $cx = if ($rightSide) { 1420 } else { 884 }
  $cy = 810 + $verticalOffset
  $topicWidth = Get-TopicWidth -Text $branches[$i] -Minimum 118 -Maximum 280 -Padding 58
  $beginX = if ($rightSide) { 1236 } else { 1068 }
  $endX = if ($rightSide) { $cx - ($topicWidth / 2) } else { $cx + ($topicWidth / 2) }

  $null = $topicIds.Add([string]$topicId)
  $null = $shapes.Add((New-Connector -Id $connectorId -BeginX $beginX -BeginY 810 -EndX $endX -EndY $cy))
  $null = $shapes.Add((New-MainTopic -Id $topicId -ConnectorId $connectorId -Text $branches[$i] -Cx $cx -Cy $cy -RightSide $rightSide))
}

$subLevel = [string]::Join(";", $topicIds)
$allShapes = (New-MainIdea -Text $Title -SubLevel $subLevel) + [Environment]::NewLine + [string]::Join([Environment]::NewLine, $shapes)
$documentGuid = [guid]::NewGuid().ToString("B")
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$documentXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Document Version="8.5.0" DocGuid="$documentGuid">
    <Properties>
        <AutoLayout V="1"/>
        <TimelineWidth V="1000"/>
        <CalloutLayout V="1"/>
        <ShowGroupName V="1"/>
        <Dpi V="1"/>
        <ActiveIndex V="0"/>
        <ScreenWidth V="2560"/>
        <ScreenHeight V="1440"/>
        <Platform V="win"/>
        <ModifyPlatform V="win"/>
        <Creator V="edrawmax-diagram"/>
        <Modifier V="edrawmax-diagram"/>
        <CreatedDate V="$now"/>
        <ModifiedDate V="$now"/>
        <Pages V="page"/>
        <QuicklyCreate/>
    </Properties>
    <GanttOption>
        <WorkDay V="1;1;1;1;1;0;0"/>
        <MajorTick V="3"/>
        <MinorTick V="0"/>
        <StartDate V="0"/>
        <FinishDate V="0"/>
        <StartTime V="28800"/>
        <FinishTime V="57600"/>
        <UnitWidth V="100"/>
        <ChangeMinor V="0"/>
    </GanttOption>
    <MarkSheet/>
</Document>
"@

$pageXml = @"
<?xml version="1.0"?><Page ID="100" Type="Page" Name="Page-1" Zoom="1" QuickMask="0"><PageProps><Width V="2304"/><Height V="1620"/><CX V="1152" B="1" P="0"/><CY V="810" B="2" P="0"/><ScrollX V="0.501311"/><ScrollY V="0.507132"/></PageProps><Layout><HSpacing V="30"/><VSpacing V="30"/><Layout V="8"/><SectorAlign V="1"/></Layout><FillFormat/><PrintSetup FittoSheet="1" HSheet="1" VSheet="1" Background="1" Width="210" Height="297" Unit="mm" LeftMargin="10" TopMargin="10" RightMargin="10" BottomMargin="10"/><Theme ID="40" Rainbow="0" Effect="0" Name="Edraw"><ThemeColor V="3"/><ThemeEffect V="40"/><ThemeText V="40"/><ThemeShape V="40"/></Theme>$allShapes</Page>
"@

Add-Type -AssemblyName System.IO.Compression.FileSystem
$templateZip = $null
$targetZip = $null
$utf8NoBom = [Text.UTF8Encoding]::new($false)

try {
  $templateZip = [IO.Compression.ZipFile]::OpenRead($resolvedTemplate)
  $targetZip = [IO.Compression.ZipFile]::Open($temporaryPath, [IO.Compression.ZipArchiveMode]::Create)

  foreach ($item in @(
      @{ Name = "document.xml"; Content = $documentXml },
      @{ Name = "page/page.xml"; Content = $pageXml },
      @{ Name = "rels/page_rels.xml"; Content = "<?xml version=""1.0"" encoding=""utf-8""?>`n<Relationships/>`n" }
    )) {
    $entry = $targetZip.CreateEntry($item.Name, [IO.Compression.CompressionLevel]::Optimal)
    $writer = [IO.StreamWriter]::new($entry.Open(), $utf8NoBom)
    $writer.Write($item.Content)
    $writer.Dispose()
  }

  foreach ($name in @("theme.xml", "thumbnail.png")) {
    $sourceEntry = $templateZip.GetEntry($name)
    if ($null -ne $sourceEntry) {
      $targetEntry = $targetZip.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
      $sourceStream = $sourceEntry.Open()
      $targetStream = $targetEntry.Open()
      $sourceStream.CopyTo($targetStream)
      $targetStream.Dispose()
      $sourceStream.Dispose()
    }
  }
}
finally {
  if ($null -ne $targetZip) {
    $targetZip.Dispose()
  }

  if ($null -ne $templateZip) {
    $templateZip.Dispose()
  }
}

try {
  $validationZip = [IO.Compression.ZipFile]::OpenRead($temporaryPath)
  try {
    foreach ($requiredEntry in @("document.xml", "page/page.xml", "rels/page_rels.xml", "theme.xml", "thumbnail.png")) {
      if ($null -eq $validationZip.GetEntry($requiredEntry)) {
        throw "Generated package is missing required entry: $requiredEntry"
      }
    }

    foreach ($xmlEntryName in @("document.xml", "page/page.xml", "rels/page_rels.xml", "theme.xml")) {
      $xmlEntry = $validationZip.GetEntry($xmlEntryName)
      $reader = [IO.StreamReader]::new($xmlEntry.Open())
      try {
        [void][xml]$reader.ReadToEnd()
      }
      finally {
        $reader.Dispose()
      }
    }
  }
  finally {
    $validationZip.Dispose()
  }

  Move-Item -LiteralPath $temporaryPath -Destination $outputPath -Force:$Force
}
finally {
  if (Test-Path -LiteralPath $temporaryPath) {
    Remove-Item -LiteralPath $temporaryPath -Force
  }
}

if ($Open) {
  $command = Get-Command mindmaster -ErrorAction SilentlyContinue
  if ($null -ne $command) {
    & $command.Source $outputPath
  }
  else {
    $executable = Get-ChildItem -LiteralPath (Join-Path $env:ProgramFiles "Edrawsoft") -Directory -Filter "MindMaster*" -ErrorAction SilentlyContinue |
      ForEach-Object { Join-Path $_.FullName "MindMaster.exe" } |
      Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
      Select-Object -First 1
    if (-not $executable) {
      throw "MindMaster executable not found. File was generated successfully: $outputPath"
    }
    Start-Process -FilePath $executable -ArgumentList @($outputPath)
  }
}

Get-Item -LiteralPath $outputPath
