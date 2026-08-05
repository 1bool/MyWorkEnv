param([switch]$Force)
$fontsDir = [Environment]::GetFolderPath('UserProfile') + '\fonts\NerdFonts'
if (-not (Test-Path $fontsDir)) { Write-Host "No fonts. Run 'just fonts' first."; exit 1 }

$shell = New-Object -ComObject Shell.Application
$fonts = $shell.Namespace(0x14)
$regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

$installed = @{}
$fontsTargetDir = [Environment]::GetFolderPath('LocalApplicationData') + '\Microsoft\Windows\Fonts'
try {
    $regProps = (Get-ItemProperty -Path $regPath).PSObject.Properties
    foreach ($p in $regProps) {
        $val = $p.Value
        if ($val -and $val -is [string]) {
            $fn = [System.IO.Path]::GetFileName($val)
            # Must exist in registry AND on disk
            if (Test-Path (Join-Path $fontsTargetDir $fn)) {
                $installed[$fn] = $true
            }
        }
    }
} catch {}

# Clean orphaned files (no registry entry)
Get-ChildItem -Path $fontsTargetDir -Include *.ttf,*.otf | Where-Object {
    $_.Name -match 'NerdFont' -and -not $installed.ContainsKey($_.Name)
} | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "  Cleaned orphan: $($_.Name)"
}

# Collect missing fonts
$tmp = Join-Path $env:TEMP "nerd-fonts-batch"
if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$total = 0

$families = Get-ChildItem -Path $fontsDir -Directory
foreach ($dir in $families) {
    $name = $dir.Name
    $ttfs = @(Get-ChildItem -Path $dir.FullName | Where-Object {
        ($_.Extension -match '\.(ttf|otf)$') -and ($_.Name -notmatch 'Propo')
    })
    $missing = @($ttfs | Where-Object { -not $installed.ContainsKey($_.Name) })

    if ($missing.Count -eq 0) {
        if ($Force) { Write-Host "  ${name} (up to date)" }
        else { Write-Host "  ${name} (already installed)" }
        continue
    }

    Write-Host "  ${name}: installing $($missing.Count) fonts"
    foreach ($f in $missing) {
        Copy-Item $f.FullName -Destination $tmp
        $total++
    }
}

if ($total -eq 0) {
    Write-Host "All fonts installed."
    Remove-Item -Recurse -Force $tmp
    exit 0
}

# Clean existing files + registry entries for fonts we're installing
foreach ($f in $missing) {
    $target = Join-Path $fontsTargetDir $f.Name
    if (Test-Path $target) { Remove-Item -Force $target }
    $base = [IO.Path]::GetFileNameWithoutExtension($f.Name)
    $ext = [IO.Path]::GetExtension($f.Name)
    Get-ChildItem -Path $fontsTargetDir -Filter "$($base)_*$ext" -ErrorAction SilentlyContinue | Remove-Item -Force
    # Also clean stale registry entries
    $regProps | Where-Object { $_.Value -like "*$base*" } | ForEach-Object {
        Remove-ItemProperty -Path $regPath -Name $_.Name -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "Installing $total fonts in one batch..."
$batch = $shell.Namespace($tmp)
$fonts.CopyHere($batch.Items(), 0x614)
Start-Sleep -Seconds 5

Remove-Item -Recurse -Force $tmp
Write-Host "Done."
