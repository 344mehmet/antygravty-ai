# =============================================================
# Docker Veri Güvenli Taşıma Scripti (Veri Kaybı Yok)
# WSL2 Export/Import ile Docker data harici diske taşıma
# Antigravity AI tarafından oluşturuldu
# =============================================================

param(
    [string]$TargetDrive = "D:",
    [switch]$BackupOnly,
    [switch]$Execute
)

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Docker Veri Güvenli Taşıma Aracı (Veri Kaybı Yok)       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Hedef dizinler
$targetPath = "$TargetDrive\Docker"
$exportPath = "$targetPath\docker-desktop-data.tar"
$importPath = "$targetPath\wsl"

# 1. Mevcut Docker durumunu kontrol et
Write-Host "[1/7] Docker durumu kontrol ediliyor..." -ForegroundColor Yellow
$wslList = wsl --list -v 2>&1
Write-Host "$wslList" -ForegroundColor Gray

# 2. Mevcut VHDX boyutunu göster
Write-Host ""
Write-Host "[2/7] Mevcut Docker data boyutu hesaplanıyor..." -ForegroundColor Yellow
$vhdxPath = "$env:LOCALAPPDATA\Docker\wsl\data\ext4.vhdx"
if (Test-Path $vhdxPath) {
    $vhdxSize = [math]::Round((Get-Item $vhdxPath).Length / 1GB, 2)
    Write-Host "  Mevcut VHDX: $vhdxSize GB" -ForegroundColor White
    Write-Host "  Konum: $vhdxPath" -ForegroundColor Gray
} else {
    Write-Host "  [UYARI] VHDX dosyası bulunamadı" -ForegroundColor Yellow
}

# 3. Hedef disk alanını kontrol et
Write-Host ""
Write-Host "[3/7] Hedef disk kontrol ediliyor ($TargetDrive)..." -ForegroundColor Yellow
try {
    $targetDisk = Get-PSDrive -Name ($TargetDrive -replace ':', '')
    $freeSpace = [math]::Round($targetDisk.Free / 1GB, 2)
    Write-Host "  Boş alan: $freeSpace GB" -ForegroundColor Green
    
    if ($freeSpace -lt ($vhdxSize * 2)) {
        Write-Host "  [UYARI] Taşıma için en az $($vhdxSize * 2) GB boş alan gerekli!" -ForegroundColor Red
    }
} catch {
    Write-Host "  [HATA] Hedef disk bulunamadı: $TargetDrive" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  TASIMA ADIMLARI (VERİ KAYBI YOK)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Adım 1: Docker Desktop'u tamamen kapatın" -ForegroundColor White
Write-Host "Adım 2: PowerShell'de (Yönetici): wsl --shutdown" -ForegroundColor White
Write-Host "Adım 3: Export: wsl --export docker-desktop-data `"$exportPath`"" -ForegroundColor White
Write-Host "Adım 4: Unregister: wsl --unregister docker-desktop-data" -ForegroundColor White
Write-Host "Adım 5: Import: wsl --import docker-desktop-data `"$importPath`" `"$exportPath`" --version 2" -ForegroundColor White
Write-Host "Adım 6: Docker Desktop'u başlatın" -ForegroundColor White
Write-Host "Adım 7: TAR dosyasını silin (isteğe bağlı)" -ForegroundColor White
Write-Host ""

if ($Execute) {
    Write-Host "[4/7] Docker Desktop kapatılıyor..." -ForegroundColor Yellow
    $dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
    if ($dockerProcess) {
        Stop-Process -Name "Docker Desktop" -Force
        Start-Sleep -Seconds 5
    }
    
    Write-Host "[5/7] WSL kapatılıyor..." -ForegroundColor Yellow
    wsl --shutdown
    Start-Sleep -Seconds 3
    
    Write-Host "[6/7] Hedef dizin oluşturuluyor..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $importPath -Force | Out-Null
    
    Write-Host "[7/7] Docker data export ediliyor (bu uzun sürebilir)..." -ForegroundColor Yellow
    Write-Host "  Lütfen bekleyin, veri boyutuna göre 5-30 dakika sürebilir..." -ForegroundColor Gray
    wsl --export docker-desktop-data $exportPath
    
    if (Test-Path $exportPath) {
        $tarSize = [math]::Round((Get-Item $exportPath).Length / 1GB, 2)
        Write-Host "  [BASARILI] Export tamamlandı: $tarSize GB" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "SONRAKİ ADIMLAR (MANUEL):" -ForegroundColor Cyan
        Write-Host "1. wsl --unregister docker-desktop-data" -ForegroundColor White
        Write-Host "2. wsl --import docker-desktop-data `"$importPath`" `"$exportPath`" --version 2" -ForegroundColor White
        Write-Host "3. Docker Desktop'u başlatın" -ForegroundColor White
    } else {
        Write-Host "  [HATA] Export başarısız!" -ForegroundColor Red
    }
} else {
    Write-Host "[BİLGİ] Bu script şu anda sadece bilgi gösteriyor." -ForegroundColor Cyan
    Write-Host "        Taşımayı başlatmak için: .\Docker_Tasi_Script.ps1 -Execute" -ForegroundColor Cyan
    Write-Host "        Farklı disk için: .\Docker_Tasi_Script.ps1 -TargetDrive E: -Execute" -ForegroundColor Cyan
}

Write-Host ""
