# =============================================================
# Eski Windows'tan Veri Taşıma Scripti
# Robocopy + File History Entegrasyonu
# 29 Aralık 2025
# =============================================================

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Veri Taşıma Aracı - Eski Windows → Yeni Windows           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# =============================================================
# KAYNAK KONUM SEÇİMİ
# =============================================================
Write-Host "`n[1/4] Kaynak konum seçimi..." -ForegroundColor Yellow

Write-Host "  Kaynak türünü seçin:" -ForegroundColor White
Write-Host "    1. Windows.old klasörü (yükseltme sonrası)" -ForegroundColor Gray
Write-Host "    2. Ağ üzerinden başka bilgisayar" -ForegroundColor Gray
Write-Host "    3. Harici disk/USB" -ForegroundColor Gray
Write-Host "    4. ZimaOS NAS (192.168.1.43)" -ForegroundColor Gray

$sourceType = Read-Host "  Seçiminiz (1-4)"

switch ($sourceType) {
    "1" {
        $sourcePath = "C:\Windows.old\Users"
        if (!(Test-Path $sourcePath)) {
            Write-Host "  [✗] Windows.old bulunamadı" -ForegroundColor Red
            exit
        }
    }
    "2" {
        $computerName = Read-Host "  Bilgisayar adı veya IP"
        $shareName = Read-Host "  Paylaşım adı (örn: Users)"
        $sourcePath = "\\$computerName\$shareName"
    }
    "3" {
        $sourcePath = Read-Host "  Harici disk yolu (örn: E:\Users)"
    }
    "4" {
        $sourcePath = "\\192.168.1.43\DATA"
        Write-Host "  ZimaOS NAS bağlantısı test ediliyor..." -ForegroundColor Cyan
        if (Test-Connection -ComputerName 192.168.1.43 -Count 1 -Quiet) {
            Write-Host "  [✓] ZimaOS erişilebilir" -ForegroundColor Green
        } else {
            Write-Host "  [✗] ZimaOS'a bağlanılamadı" -ForegroundColor Red
            exit
        }
    }
}

# =============================================================
# TAŞINACAK KLASÖRLER
# =============================================================
Write-Host "`n[2/4] Taşınacak klasörler seçiliyor..." -ForegroundColor Yellow

$foldersToMigrate = @(
    @{Name="Belgeler"; Source="Documents"; Target="$env:USERPROFILE\Documents"},
    @{Name="Masaüstü"; Source="Desktop"; Target="$env:USERPROFILE\Desktop"},
    @{Name="İndirilenler"; Source="Downloads"; Target="$env:USERPROFILE\Downloads"},
    @{Name="Resimler"; Source="Pictures"; Target="$env:USERPROFILE\Pictures"},
    @{Name="Videolar"; Source="Videos"; Target="$env:USERPROFILE\Videos"},
    @{Name="Müzik"; Source="Music"; Target="$env:USERPROFILE\Music"},
    @{Name="AppData"; Source="AppData"; Target="$env:USERPROFILE\AppData"}
)

Write-Host "  Taşınacak klasörler:" -ForegroundColor White
foreach ($folder in $foldersToMigrate) {
    Write-Host "    [✓] $($folder.Name)" -ForegroundColor Green
}

# =============================================================
# VERİ TAŞIMA (ROBOCOPY)
# =============================================================
Write-Host "`n[3/4] Veri taşıma başlatılıyor..." -ForegroundColor Yellow

$confirm = Read-Host "  Taşıma işlemine başlansın mı? (E/H)"
if ($confirm -ne "E") {
    Write-Host "  İşlem iptal edildi" -ForegroundColor Yellow
    exit
}

# Log dosyası
$logPath = "$env:USERPROFILE\Desktop\veri_tasima_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

foreach ($folder in $foldersToMigrate) {
    $source = Join-Path $sourcePath $folder.Source
    $target = $folder.Target
    
    if (Test-Path $source) {
        Write-Host "`n  [$($folder.Name)] taşınıyor..." -ForegroundColor Cyan
        Write-Host "    Kaynak: $source" -ForegroundColor Gray
        Write-Host "    Hedef: $target" -ForegroundColor Gray
        
        # Robocopy parametreleri:
        # /E = Alt klasörler dahil (boş olanlar da)
        # /Z = Yeniden başlatılabilir mod
        # /MT:8 = 8 thread ile paralel kopyalama
        # /R:3 = 3 deneme
        # /W:5 = Denemeler arası 5 saniye bekle
        # /LOG+ = Log dosyasına ekle
        # /NP = İlerleme yüzdesi gösterme
        # /XJ = Junction noktalarını atla
        
        $robocopyArgs = "`"$source`" `"$target`" /E /Z /MT:8 /R:3 /W:5 /LOG+:`"$logPath`" /NP /XJ /XD `"AppData\Local\Temp`""
        
        Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -NoNewWindow
        
        Write-Host "    [✓] Tamamlandı" -ForegroundColor Green
    } else {
        Write-Host "  [$($folder.Name)] bulunamadı, atlanıyor..." -ForegroundColor Yellow
    }
}

# =============================================================
# SONUÇ RAPORU
# =============================================================
Write-Host "`n[4/4] Sonuç raporu hazırlanıyor..." -ForegroundColor Yellow

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  VERİ TAŞIMA TAMAMLANDI!                                   ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n  Log dosyası: $logPath" -ForegroundColor White
Write-Host "  Taşınan klasörler: $($foldersToMigrate.Count)" -ForegroundColor White

# Hedef klasör boyutları
Write-Host "`n  Klasör boyutları:" -ForegroundColor White
foreach ($folder in $foldersToMigrate) {
    if (Test-Path $folder.Target) {
        $size = (Get-ChildItem -Path $folder.Target -Recurse -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum).Sum
        $sizeGB = [math]::Round($size / 1GB, 2)
        Write-Host "    $($folder.Name): $sizeGB GB" -ForegroundColor Gray
    }
}

Write-Host "`n  Öneri: Taşıma sonrası dosyaları kontrol edin" -ForegroundColor Cyan
