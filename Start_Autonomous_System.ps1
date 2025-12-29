# ============================================
# OTONOM AI SİSTEMİ BAŞLATICI
# 344Mehmet - 29 Aralık 2025
# ============================================

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "  OTONOM AI GELIR SISTEMI                                  " -ForegroundColor Cyan
Write-Host "  Trading + Coding + Job Hunting                           " -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan

$workDir = "c:\Users\win11.2025\Desktop\antygravty google id"
Set-Location $workDir

# 1. OLLAMA KONTROLÜ
Write-Host "`n[1/5] Ollama kontrol ediliyor..." -ForegroundColor Yellow

$ollamaProcess = Get-Process -Name "ollama*" -ErrorAction SilentlyContinue
if (-not $ollamaProcess) {
    Write-Host "  Ollama baslatiliyor..." -ForegroundColor Cyan
    Start-Process -FilePath "$env:LOCALAPPDATA\Programs\Ollama\ollama app.exe" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing -TimeoutSec 5
    $models = ($response.Content | ConvertFrom-Json).models
    Write-Host "  [OK] Ollama calisıyor - $($models.Count) model" -ForegroundColor Green
}
catch {
    Write-Host "  [!] Ollama API erisemiyor" -ForegroundColor Yellow
}

# 2. MODEL KONTROLÜ
Write-Host "`n[2/5] Modeller kontrol ediliyor..." -ForegroundColor Yellow
Write-Host "  - 344mehmet-assistant" -ForegroundColor Gray
Write-Host "  - qwen2.5:1.5b" -ForegroundColor Gray
Write-Host "  - nomic-embed-text" -ForegroundColor Gray

# 3. TRADING BOT DURUMU
Write-Host "`n[3/5] Trading bot kontrol ediliyor..." -ForegroundColor Yellow

$tradingBotPath = Join-Path $workDir "trading_bot.py"
$agentSystemPath = Join-Path $workDir "autonomous_agent_system.py"

if (Test-Path $tradingBotPath) {
    Write-Host "  [OK] trading_bot.py mevcut" -ForegroundColor Green
} else {
    Write-Host "  [X] trading_bot.py bulunamadi" -ForegroundColor Red
}

if (Test-Path $agentSystemPath) {
    Write-Host "  [OK] autonomous_agent_system.py mevcut" -ForegroundColor Green
} else {
    Write-Host "  [X] autonomous_agent_system.py bulunamadi" -ForegroundColor Red
}

# 4. ENV DOSYASI KONTROLÜ
Write-Host "`n[4/5] Env dosyasi kontrol ediliyor..." -ForegroundColor Yellow

$envPath = Join-Path $workDir ".env"
if (Test-Path $envPath) {
    Write-Host "  [OK] .env dosyasi mevcut" -ForegroundColor Green
} else {
    Write-Host "  [!] .env dosyasi bulunamadi - .env.example kopyalanmali" -ForegroundColor Yellow
}

# 5. TRADING SINYAL TESTİ
Write-Host "`n[5/5] AI Trading sinyali alinıyor..." -ForegroundColor Yellow

try {
    $body = @{
        model = "344mehmet-assistant"
        prompt = "BTC 100000 dolar. Kisa trading sinyali: BUY, SELL veya HOLD?"
        stream = $false
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/generate" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing -TimeoutSec 60
    $result = ($response.Content | ConvertFrom-Json).response
    Write-Host "  AI Sinyal: $($result.Substring(0, [Math]::Min($result.Length, 80)))..." -ForegroundColor Green
}
catch {
    Write-Host "  [!] AI sinyal alinamadi" -ForegroundColor Yellow
}

# RAPOR
Write-Host "`n===========================================================" -ForegroundColor Green
Write-Host "  SISTEM HAZIR!                                             " -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Green

Write-Host "`nDosyalar:" -ForegroundColor White
Write-Host "  - autonomous_agent_system.py - Ana otonom sistem" -ForegroundColor Gray
Write-Host "  - trading_bot.py - Binance/OKX trading" -ForegroundColor Gray
Write-Host "  - rag_system.py - RAG ile zeki cevaplar" -ForegroundColor Gray

Write-Host "`nKullanim:" -ForegroundColor White
Write-Host "  ollama run 344mehmet-assistant" -ForegroundColor Yellow
