# =============================================================
# Sistem Temizlik ve Depolama Yönetim Scripti
# Antigravity AI tarafından oluşturuldu
# =============================================================

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    Sistem Temizlik ve Depolama Yonetim Araci             ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 1. TEMP DOSYALARI TEMIZLIGI
Write-Host "[1/5] Temp dosyalari analiz ediliyor..." -ForegroundColor Yellow
$tempPath = "$env:LOCALAPPDATA\Temp"
$tempSize = (Get-ChildItem $tempPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "  Temp boyutu: $([math]::Round($tempSize,2)) GB" -ForegroundColor Gray

$confirm = Read-Host "  Temp dosyalarini temizlemek istiyor musunuz? (E/H)"
if ($confirm -eq "E") {
    Remove-Item "$tempPath\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [BASARILI] Temp dosyalari temizlendi" -ForegroundColor Green
}

# 2. WINDOWS UPDATE TEMIZLIGI
Write-Host ""
Write-Host "[2/5] Windows Update cache kontrol ediliyor..." -ForegroundColor Yellow
$wuPath = "C:\Windows\SoftwareDistribution\Download"
if (Test-Path $wuPath) {
    $wuSize = (Get-ChildItem $wuPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "  Windows Update cache: $([math]::Round($wuSize,2)) GB" -ForegroundColor Gray
}

# 3. DOCKER TEMIZLIK
Write-Host ""
Write-Host "[3/5] Docker durumu kontrol ediliyor..." -ForegroundColor Yellow
try {
    $dockerStatus = docker system df --format "{{.Type}}: {{.Size}} ({{.Reclaimable}} kazanilabilir)"
    Write-Host "  Docker disk kullanimi:" -ForegroundColor Gray
    $dockerStatus | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
    
    $cleanDocker = Read-Host "  Kullanilmayan Docker verilerini temizlemek istiyor musunuz? (E/H)"
    if ($cleanDocker -eq "E") {
        docker system prune -f
        Write-Host "  [BASARILI] Docker temizlendi" -ForegroundColor Green
    }
} catch {
    Write-Host "  [UYARI] Docker Desktop calismiyor veya kurulu degil" -ForegroundColor Yellow
}

# 4. ESKI WINDOWS KURTARMA DOSYALARI
Write-Host ""
Write-Host "[4/5] Windows.old ve kurtarma dosyalari kontrol ediliyor..." -ForegroundColor Yellow
$oldWindowsPaths = @(
    "C:\Windows.old",
    "C:\`$Windows.~BT",
    "C:\`$Windows.~WS",
    "C:\`$Recycle.Bin"
)
foreach ($path in $oldWindowsPaths) {
    if (Test-Path $path) {
        try {
            $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            Write-Host "  $path: $([math]::Round($size,2)) GB" -ForegroundColor Gray
        } catch {}
    }
}

# 5. DISK OZETI
Write-Host ""
Write-Host "[5/5] Disk kullanim ozeti:" -ForegroundColor Yellow
Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Used -gt 0} | ForEach-Object {
    $usedGB = [math]::Round($_.Used/1GB, 2)
    $freeGB = [math]::Round($_.Free/1GB, 2)
    $totalGB = [math]::Round(($_.Used + $_.Free)/1GB, 2)
    $usedPercent = [math]::Round(($_.Used/($_.Used + $_.Free))*100, 1)
    Write-Host "  $($_.Name): $usedGB GB / $totalGB GB (%$usedPercent kullanim, $freeGB GB bos)" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Temizlik tamamlandi!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "ONERILER:" -ForegroundColor Cyan
Write-Host "1. Docker Desktop > Settings > Resources ile disk konumunu degistirin" -ForegroundColor White
Write-Host "2. ZimaOS > Storage > Format for ZimaOS ile harici disk ekleyin" -ForegroundColor White
Write-Host "3. Disk Temizleme araci (cleanmgr) ile sistem dosyalarini temizleyin" -ForegroundColor White
Write-Host ""
