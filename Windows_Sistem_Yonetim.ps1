# =============================================================
# Windows Sistem Bakım, Güncelleme ve Ağ Yönetim Scripti
# i7-4790 + 16GB DDR3 Sistem için
# 29 Aralık 2025
# =============================================================

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Windows Sistem Yönetim Merkezi                            ║" -ForegroundColor Cyan
Write-Host "║  i7-4790 | 16GB DDR3 | Windows 11                          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# =============================================================
# 1. SİSTEM BİLGİSİ TOPLAMA
# =============================================================
Write-Host "`n[1/8] Sistem bilgisi toplanıyor..." -ForegroundColor Yellow

$sysInfo = Get-CimInstance Win32_ComputerSystem
$osInfo = Get-CimInstance Win32_OperatingSystem
$cpuInfo = Get-CimInstance Win32_Processor
$diskInfo = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  SİSTEM BİLGİSİ" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  Bilgisayar: $($sysInfo.Name)" -ForegroundColor White
Write-Host "  İşletim Sistemi: $($osInfo.Caption)" -ForegroundColor White
Write-Host "  İşlemci: $($cpuInfo.Name)" -ForegroundColor White
Write-Host "  RAM: $([math]::Round($sysInfo.TotalPhysicalMemory / 1GB, 2)) GB" -ForegroundColor White

foreach ($disk in $diskInfo) {
    $freePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
    Write-Host "  Disk $($disk.DeviceID) $freeGB GB boş ($freePercent%)" -ForegroundColor White
}

# =============================================================
# 2. DISM - SİSTEM İMAJ ONARIMI
# =============================================================
Write-Host "`n[2/8] DISM sistem imaj kontrolü..." -ForegroundColor Yellow

$dismCheck = Read-Host "DISM taraması başlatılsın mı? (E/H)"
if ($dismCheck -eq "E") {
    Write-Host "  DISM CheckHealth çalıştırılıyor..." -ForegroundColor Cyan
    DISM /Online /Cleanup-Image /CheckHealth
    
    $dismRepair = Read-Host "  Onarım yapılsın mı? (E/H)"
    if ($dismRepair -eq "E") {
        Write-Host "  DISM RestoreHealth çalıştırılıyor (bu uzun sürebilir)..." -ForegroundColor Cyan
        DISM /Online /Cleanup-Image /RestoreHealth
    }
}

# =============================================================
# 3. SFC - SİSTEM DOSYALARI KONTROLÜ
# =============================================================
Write-Host "`n[3/8] SFC sistem dosyaları kontrolü..." -ForegroundColor Yellow

$sfcCheck = Read-Host "SFC taraması başlatılsın mı? (E/H)"
if ($sfcCheck -eq "E") {
    Write-Host "  SFC /scannow çalıştırılıyor..." -ForegroundColor Cyan
    sfc /scannow
}

# =============================================================
# 4. SÜRÜCÜ GÜNCELLEMELERİ
# =============================================================
Write-Host "`n[4/8] Sürücü güncellemeleri kontrol ediliyor..." -ForegroundColor Yellow

# Windows Update'ten sürücüleri kontrol et
try {
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Driver'")
    
    if ($searchResult.Updates.Count -gt 0) {
        Write-Host "  Mevcut sürücü güncellemeleri:" -ForegroundColor Green
        foreach ($update in $searchResult.Updates) {
            Write-Host "    - $($update.Title)" -ForegroundColor White
        }
    } else {
        Write-Host "  [✓] Tüm sürücüler güncel" -ForegroundColor Green
    }
} catch {
    Write-Host "  [!] Sürücü kontrolü yapılamadı" -ForegroundColor Yellow
}

# =============================================================
# 5. DİSK TEMİZLİĞİ
# =============================================================
Write-Host "`n[5/8] Disk temizliği yapılıyor..." -ForegroundColor Yellow

# Temp dosyalarını temizle
$tempPaths = @(
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "C:\Windows\Temp"
)

$totalCleaned = 0
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        $files = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
                 Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
        
        foreach ($file in $files) {
            try {
                $totalCleaned += $file.Length
                Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
            } catch { }
        }
    }
}

$cleanedMB = [math]::Round($totalCleaned / 1MB, 2)
Write-Host "  [✓] $cleanedMB MB geçici dosya temizlendi" -ForegroundColor Green

# Windows Update temizliği
Write-Host "  Disk Cleanup başlatılıyor..." -ForegroundColor Cyan
Start-Process cleanmgr -ArgumentList "/sagerun:1" -NoNewWindow -Wait -ErrorAction SilentlyContinue

# =============================================================
# 6. WINDOWS GÜNCELLEMELERİ
# =============================================================
Write-Host "`n[6/8] Windows güncellemeleri kontrol ediliyor..." -ForegroundColor Yellow

try {
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult = $updateSearcher.Search("IsInstalled=0 and IsHidden=0")
    
    if ($searchResult.Updates.Count -gt 0) {
        Write-Host "  Bekleyen güncellemeler:" -ForegroundColor Green
        foreach ($update in $searchResult.Updates | Select-Object -First 5) {
            Write-Host "    - $($update.Title)" -ForegroundColor White
        }
        if ($searchResult.Updates.Count -gt 5) {
            Write-Host "    ... ve $($searchResult.Updates.Count - 5) daha" -ForegroundColor Gray
        }
    } else {
        Write-Host "  [✓] Sistem güncel" -ForegroundColor Green
    }
} catch {
    Write-Host "  [!] Güncelleme kontrolü yapılamadı" -ForegroundColor Yellow
}

# =============================================================
# 7. AĞDAKİ CİHAZLARI TARA
# =============================================================
Write-Host "`n[7/8] Ağdaki cihazlar taranıyor..." -ForegroundColor Yellow

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  AĞDAKİ CİHAZLAR (192.168.1.x)" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

# ARP tablosundan cihazları al
$arpEntries = arp -a | Select-String "192.168.1" | ForEach-Object { $_.ToString().Trim() }

$knownDevices = @{
    "192.168.1.1" = "Router/Gateway"
    "192.168.1.43" = "ZimaOS NAS"
    "192.168.1.46" = "Bu Bilgisayar (Wi-Fi)"
    "192.168.1.62" = "Bu Bilgisayar (Ethernet)"
}

foreach ($entry in $arpEntries) {
    if ($entry -match "(\d+\.\d+\.\d+\.\d+)\s+([0-9a-f-]+)") {
        $ip = $Matches[1]
        $mac = $Matches[2]
        $deviceName = if ($knownDevices.ContainsKey($ip)) { $knownDevices[$ip] } else { "Bilinmeyen" }
        Write-Host "  $ip`t$mac`t$deviceName" -ForegroundColor White
    }
}

# =============================================================
# 8. UZAK YÖNETIM (WinRM) DURUMU
# =============================================================
Write-Host "`n[8/8] Uzak yönetim (WinRM) durumu..." -ForegroundColor Yellow

$winrmStatus = Get-Service WinRM -ErrorAction SilentlyContinue
if ($winrmStatus.Status -eq "Running") {
    Write-Host "  [✓] WinRM servisi çalışıyor" -ForegroundColor Green
} else {
    Write-Host "  [!] WinRM servisi çalışmıyor" -ForegroundColor Yellow
    $enableWinRM = Read-Host "  WinRM etkinleştirilsin mi? (E/H)"
    if ($enableWinRM -eq "E") {
        Enable-PSRemoting -Force -SkipNetworkProfileCheck
        Write-Host "  [✓] WinRM etkinleştirildi" -ForegroundColor Green
    }
}

# =============================================================
# RAPOR
# =============================================================
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  SİSTEM BAKIM TAMAMLANDI!                                  ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Sonraki adımlar:" -ForegroundColor White
Write-Host "    1. Eski Windows verilerini taşımak için: .\Veri_Tasima_Script.ps1" -ForegroundColor Cyan
Write-Host "    2. Ağ cihazlarını yönetmek için: .\Ag_Yonetim_Script.ps1" -ForegroundColor Cyan
Write-Host "    3. Yedekleme için: .\Yedekleme_Script.ps1" -ForegroundColor Cyan
Write-Host ""
