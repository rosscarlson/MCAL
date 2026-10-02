# Generates src/MCAL/Assets/MCAL.ico (multi-size, PNG-compressed entries).
# Run with Windows PowerShell 5.1: powershell -File tools\make-icon.ps1
Add-Type -AssemblyName System.Drawing

$out = Join-Path $PSScriptRoot '..\src\MCAL\Assets\MCAL.ico'
$sizes = 16, 24, 32, 48, 64, 128, 256
$pngs = @()

foreach ($s in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap $s, $s
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.Clear([System.Drawing.Color]::Transparent)

    # rounded square background
    $r = [single]($s * 0.22)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $w = [single]($s - 1)
    $path.AddArc(0, 0, $r * 2, $r * 2, 180, 90)
    $path.AddArc($w - $r * 2, 0, $r * 2, $r * 2, 270, 90)
    $path.AddArc($w - $r * 2, $w - $r * 2, $r * 2, $r * 2, 0, 90)
    $path.AddArc(0, $w - $r * 2, $r * 2, $r * 2, 90, 90)
    $path.CloseFigure()
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Point 0, 0), (New-Object System.Drawing.Point $s, $s), ([System.Drawing.Color]::FromArgb(255, 0, 95, 184)), ([System.Drawing.Color]::FromArgb(255, 76, 194, 255))
    $g.FillPath($brush, $path)

    # level-meter bars
    $heights = 0.30, 0.55, 0.80, 0.55, 0.30
    $n = $heights.Count
    $margin = $s * 0.18
    $gap = $s * 0.06
    $barW = ($s - 2 * $margin - ($n - 1) * $gap) / $n
    $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    for ($i = 0; $i -lt $n; $i++) {
        $h = $heights[$i] * ($s - 2 * $margin)
        $x = $margin + $i * ($barW + $gap)
        $y = ($s - $h) / 2
        $g.FillRectangle($white, [single]$x, [single]$y, [single]$barW, [single]$h)
    }
    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngs += , $ms.ToArray()
    $bmp.Dispose()
}

$fs = [System.IO.File]::Create($out)
$bw = New-Object System.IO.BinaryWriter $fs
$bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]
    $dim = if ($s -ge 256) { 0 } else { $s }
    $bw.Write([byte]$dim); $bw.Write([byte]$dim); $bw.Write([byte]0); $bw.Write([byte]0)
    $bw.Write([uint16]1); $bw.Write([uint16]32)
    $bw.Write([uint32]$pngs[$i].Length); $bw.Write([uint32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($p in $pngs) { $bw.Write($p) }
$bw.Close()
Write-Host "Wrote $out"
