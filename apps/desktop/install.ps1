# ============================================================
#  SuXiaoRui - Install Script (PowerShell)
#  Windows 10/11 | No admin required
# ============================================================
param(
    [string]$InstallPath = "$env:LOCALAPPDATA\SuXiaoRui",
    [switch]$Uninstall
)

$AppExe = "SuXiaoRui.exe"
$AppDir = $InstallPath

function Pause-Exit {
    Write-Host ""
    Write-Host "Press Enter to exit..." -ForegroundColor Yellow
    Read-Host
    exit
}

# ===== Uninstall =====
if ($Uninstall) {
    Write-Host "Uninstalling..." -ForegroundColor Yellow
    try {
        $procs = Get-Process -Name "SuXiaoRui" -ErrorAction SilentlyContinue
        if ($procs) { $procs | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2 }
    } catch {}
    $desktop = [Environment]::GetFolderPath("Desktop")
    $link = Join-Path $desktop "SuXiaoRui.lnk"
    if (Test-Path $link) { Remove-Item $link -Force -ErrorAction SilentlyContinue }
    $startMenu = [Environment]::GetFolderPath("Programs")
    $startDir = Join-Path $startMenu "SuXiaoRui"
    if (Test-Path $startDir) { Remove-Item $startDir -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $AppDir) { Remove-Item $AppDir -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Host "Uninstall complete!" -ForegroundColor Green
    Pause-Exit
}

# ===== Install =====
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SuXiaoRui Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir = Join-Path $ScriptDir "win-unpacked"
if (-not (Test-Path $SourceDir)) {
    $SourceDir = Join-Path $ScriptDir "release\win-unpacked"
}

Write-Host "Script:  $ScriptDir" -ForegroundColor Gray
Write-Host "Source:  $SourceDir" -ForegroundColor Gray

if (-not (Test-Path $SourceDir)) {
    Write-Host ""
    Write-Host "[ERROR] win-unpacked folder not found!" -ForegroundColor Red
    Write-Host "Make sure win-unpacked is in the same folder as this script." -ForegroundColor Red
    Write-Host "Current folder contents:" -ForegroundColor Red
    Get-ChildItem $ScriptDir | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }
    Pause-Exit
}

$SourceExe = Join-Path $SourceDir $AppExe
if (-not (Test-Path $SourceExe)) {
    Write-Host "[ERROR] $AppExe not found in $SourceDir" -ForegroundColor Red
    Pause-Exit
}

Write-Host " [1/4] Installing to: $AppDir" -ForegroundColor White
if (Test-Path $AppDir) {
    Write-Host "  Overwriting existing installation..." -ForegroundColor Gray
    try {
        $procs = Get-Process -Name "SuXiaoRui" -ErrorAction SilentlyContinue
        if ($procs) { $procs | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2 }
    } catch {}
    Remove-Item $AppDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host " [2/4] Copying files (may take 1-2 min)..." -ForegroundColor White
try {
    Copy-Item -Path $SourceDir -Destination $AppDir -Recurse -ErrorAction Stop
    Write-Host "  Copy complete" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Copy failed: $_" -ForegroundColor Red
    Pause-Exit
}

$TargetExe = Join-Path $AppDir $AppExe

Write-Host " [3/4] Creating desktop shortcut..." -ForegroundColor White
$desktop = [Environment]::GetFolderPath("Desktop")
$link = Join-Path $desktop "SuXiaoRui.lnk"
try {
    $WS = New-Object -ComObject WScript.Shell
    $SC = $WS.CreateShortcut($link)
    $SC.TargetPath = $TargetExe
    $SC.WorkingDirectory = $AppDir
    $SC.Description = "SuXiaoRui"
    $SC.IconLocation = "$TargetExe,0"
    $SC.Save()
    Write-Host "  Desktop shortcut created" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Desktop shortcut failed: $_" -ForegroundColor Yellow
}

Write-Host " [4/4] Creating Start Menu..." -ForegroundColor White
$startMenu = [Environment]::GetFolderPath("Programs")
$startDir = Join-Path $startMenu "SuXiaoRui"
try {
    New-Item -ItemType Directory -Path $startDir -Force -ErrorAction SilentlyContinue | Out-Null
    $startLink = Join-Path $startDir "SuXiaoRui.lnk"
    $SC2 = $WS.CreateShortcut($startLink)
    $SC2.TargetPath = $TargetExe
    $SC2.WorkingDirectory = $AppDir
    $SC2.Description = "SuXiaoRui"
    $SC2.IconLocation = "$TargetExe,0"
    $SC2.Save()
    Write-Host "  Start Menu created" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Start Menu failed: $_" -ForegroundColor Yellow
}

# Copy uninstall script
$UninstallPs1 = Join-Path $AppDir "uninstall.ps1"
@"
Write-Host "Uninstalling SuXiaoRui..." -ForegroundColor Yellow
try { `$p = Get-Process -Name "SuXiaoRui" -ErrorAction SilentlyContinue; if (`$p) { `$p | Stop-Process -Force }; Start-Sleep 2 } catch {}
Remove-Item "$link" -Force -ErrorAction SilentlyContinue
Remove-Item "$startDir" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$AppDir" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "SuXiaoRui uninstalled!" -ForegroundColor Green
Read-Host "Press Enter to exit"
"@ | Out-File -FilePath $UninstallPs1 -Encoding UTF8

$UninstallBat = Join-Path $AppDir "uninstall.bat"
@"
@echo off
chcp 65001 >nul
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0uninstall.ps1"
"@ | Out-File -FilePath $UninstallBat -Encoding ASCII

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Install Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Folder:     $AppDir" -ForegroundColor White
Write-Host "  Desktop:    $link" -ForegroundColor White
Write-Host "  Start Menu: $startDir" -ForegroundColor White
Write-Host ""
Write-Host "  Run 'uninstall.bat' in install folder to remove." -ForegroundColor Cyan

Pause-Exit
