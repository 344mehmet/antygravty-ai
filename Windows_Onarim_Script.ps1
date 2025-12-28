# =============================================================
# Windows Sistem Onarım ve ZimaOS Yapılandırma Scripti
# YÖNETİCİ OLARAK ÇALIŞTIRIN!
# =============================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Windows + ZimaOS Onarim Scripti" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Admin kontrolu
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[HATA] Bu script yonetici olarak calistirilmali!" -ForegroundColor Red
    Write-Host "PowerShell'i yonetici olarak acip tekrar calistirin." -ForegroundColor Yellow
    exit 1
}

Write-Host "[BASARILI] Yonetici yetkisi onaylandi" -ForegroundColor Green
Write-Host ""

# 1. DISM Onarimi
Write-Host "[1/4] DISM ile Windows onarimi baslatiliyor..." -ForegroundColor Yellow
Write-Host "Bu islem 10-30 dakika surebilir, lutfen bekleyin..." -ForegroundColor Gray
DISM /Online /Cleanup-Image /RestoreHealth
Write-Host ""

# 2. SFC Yeniden Tarama
Write-Host "[2/4] SFC ile sistem dosyalari yeniden taraniyor..." -ForegroundColor Yellow
sfc /scannow
Write-Host ""

# 3. Windows Update Temizlik
Write-Host "[3/4] Windows Update bilesenleri temizleniyor..." -ForegroundColor Yellow
DISM /Online /Cleanup-Image /StartComponentCleanup
Write-Host ""

# 4. ZimaOS Baglanti Testi
Write-Host "[4/4] ZimaOS baglantisi kontrol ediliyor..." -ForegroundColor Yellow
$zimaIP = "192.168.1.43"

try {
    $ping = Test-Connection -ComputerName $zimaIP -Count 1 -Quiet
    if ($ping) {
        Write-Host "[BASARILI] ZimaOS erisebilir: $zimaIP" -ForegroundColor Green
        
        # Ollama API Testi
        try {
            $response = Invoke-WebRequest -Uri "http://$zimaIP:11434/api/tags" -UseBasicParsing -TimeoutSec 5
            Write-Host "[BASARILI] Ollama API aktif" -ForegroundColor Green
        } catch {
            Write-Host "[UYARI] Ollama API yanit vermiyor" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[UYARI] ZimaOS'a erisilemedi" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[HATA] Baglanti testi basarisiz: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ONARIM TAMAMLANDI!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Sonraki Adimlar:" -ForegroundColor Cyan
Write-Host "1. Bilgisayari yeniden baslatin" -ForegroundColor White
Write-Host "2. ZimaOS terminalinde harici disk yapilandirmasi yapin:" -ForegroundColor White
Write-Host "   http://192.168.1.43:2222" -ForegroundColor Gray
Write-Host ""
