# =============================================================
# Ağ Cihazları Yönetim Scripti
# PowerShell Remoting + WinRM
# 29 Aralık 2025
# =============================================================

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Ağ Cihazları Yönetim Merkezi                              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# =============================================================
# AĞ TARAMASI
# =============================================================
Write-Host "`n[1/5] Ağ taraması yapılıyor..." -ForegroundColor Yellow

$networkPrefix = "192.168.1"
$foundDevices = @()

Write-Host "  $networkPrefix.0/24 ağı taranıyor..." -ForegroundColor Cyan

# Hızlı ping taraması
$jobs = @()
1..254 | ForEach-Object {
    $ip = "$networkPrefix.$_"
    $jobs += Test-Connection -ComputerName $ip -Count 1 -AsJob -ErrorAction SilentlyContinue
}

$jobs | Wait-Job -Timeout 30 | Out-Null
$results = $jobs | Receive-Job -ErrorAction SilentlyContinue
$jobs | Remove-Job -Force -ErrorAction SilentlyContinue

# Bulunan cihazları listele
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  BULUNAN CİHAZLAR" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

# Bilinen cihazlar
$knownDevices = @{
    "192.168.1.1" = @{Name="Router/Gateway"; Type="Router"; Color="Yellow"}
    "192.168.1.43" = @{Name="ZimaOS NAS"; Type="NAS"; Color="Green"}
    "192.168.1.46" = @{Name="Bu PC (Wi-Fi)"; Type="ThisPC"; Color="Cyan"}
    "192.168.1.62" = @{Name="Bu PC (Ethernet)"; Type="ThisPC"; Color="Cyan"}
    "192.168.1.102" = @{Name="Windows PC"; Type="Computer"; Color="White"}
    "192.168.1.160" = @{Name="Mobil Cihaz"; Type="Mobile"; Color="Magenta"}
}

# ARP tablosunu kontrol et
$arpTable = arp -a | Select-String "192.168.1" | ForEach-Object { $_.ToString().Trim() }

foreach ($entry in $arpTable) {
    if ($entry -match "(\d+\.\d+\.\d+\.\d+)\s+([0-9a-f-]+)") {
        $ip = $Matches[1]
        $mac = $Matches[2]
        
        if ($knownDevices.ContainsKey($ip)) {
            $device = $knownDevices[$ip]
            Write-Host "  [✓] $ip`t$($device.Name)" -ForegroundColor $device.Color
        } else {
            Write-Host "  [?] $ip`t(Bilinmeyen - $mac)" -ForegroundColor Gray
        }
        
        $foundDevices += @{IP=$ip; MAC=$mac}
    }
}

# =============================================================
# WinRM DURUMU KONTROLÜ
# =============================================================
Write-Host "`n[2/5] WinRM durumu kontrol ediliyor..." -ForegroundColor Yellow

$winrmStatus = Get-Service WinRM -ErrorAction SilentlyContinue
if ($winrmStatus.Status -eq "Running") {
    Write-Host "  [✓] WinRM servisi aktif" -ForegroundColor Green
    
    # TrustedHosts listesi
    $trustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction SilentlyContinue).Value
    if ($trustedHosts) {
        Write-Host "  Güvenilir hostlar: $trustedHosts" -ForegroundColor Gray
    }
} else {
    Write-Host "  [!] WinRM servisi çalışmıyor" -ForegroundColor Yellow
}

# =============================================================
# UZAK BİLGİSAYAR YÖNETİMİ
# =============================================================
Write-Host "`n[3/5] Uzak bilgisayar yönetimi..." -ForegroundColor Yellow

function Test-RemoteAccess {
    param([string]$ComputerName)
    
    try {
        $result = Test-WSMan -ComputerName $ComputerName -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

function Invoke-RemoteCommand {
    param(
        [string]$ComputerName,
        [string]$Command,
        [PSCredential]$Credential
    )
    
    try {
        $result = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param($cmd)
            Invoke-Expression $cmd
        } -ArgumentList $Command -Credential $Credential -ErrorAction Stop
        
        return $result
    } catch {
        return "Hata: $_"
    }
}

# Menü
Write-Host "  Uzak yönetim seçenekleri:" -ForegroundColor White
Write-Host "    1. Uzak bilgisayara bağlan (Enter-PSSession)" -ForegroundColor Gray
Write-Host "    2. Uzak komut çalıştır (Invoke-Command)" -ForegroundColor Gray
Write-Host "    3. Sistem bilgisi al" -ForegroundColor Gray
Write-Host "    4. Güvenilir host ekle" -ForegroundColor Gray
Write-Host "    5. Atla" -ForegroundColor Gray

$remoteChoice = Read-Host "  Seçiminiz (1-5)"

switch ($remoteChoice) {
    "1" {
        $targetIP = Read-Host "  Hedef IP"
        $cred = Get-Credential -Message "Uzak bilgisayar kimlik bilgileri"
        Enter-PSSession -ComputerName $targetIP -Credential $cred
    }
    "2" {
        $targetIP = Read-Host "  Hedef IP"
        $command = Read-Host "  Çalıştırılacak komut"
        $cred = Get-Credential -Message "Uzak bilgisayar kimlik bilgileri"
        Invoke-RemoteCommand -ComputerName $targetIP -Command $command -Credential $cred
    }
    "3" {
        $targetIP = Read-Host "  Hedef IP"
        $cred = Get-Credential -Message "Uzak bilgisayar kimlik bilgileri"
        Invoke-Command -ComputerName $targetIP -ScriptBlock {
            Get-CimInstance Win32_ComputerSystem | Select-Object Name, Model, TotalPhysicalMemory
            Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version
        } -Credential $cred
    }
    "4" {
        $newHost = Read-Host "  Eklenecek IP veya hostname"
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value $newHost -Concatenate -Force
        Write-Host "  [✓] $newHost güvenilir hostlara eklendi" -ForegroundColor Green
    }
    "5" {
        Write-Host "  Atlandı" -ForegroundColor Gray
    }
}

# =============================================================
# ZimaOS NAS YÖNETİMİ
# =============================================================
Write-Host "`n[4/5] ZimaOS NAS durumu..." -ForegroundColor Yellow

$zimaIP = "192.168.1.43"
if (Test-Connection -ComputerName $zimaIP -Count 1 -Quiet) {
    Write-Host "  [✓] ZimaOS NAS erişilebilir" -ForegroundColor Green
    
    # Ollama API kontrolü
    try {
        $ollamaResponse = Invoke-WebRequest -Uri "http://${zimaIP}:11434/api/tags" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        $models = ($ollamaResponse.Content | ConvertFrom-Json).models
        Write-Host "  [✓] Ollama API aktif - $($models.Count) model yüklü" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Ollama API erişilemez" -ForegroundColor Yellow
    }
    
    # Web UI kontrolü
    try {
        $webResponse = Invoke-WebRequest -Uri "http://${zimaIP}" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        Write-Host "  [✓] ZimaOS Web UI aktif" -ForegroundColor Green
    } catch {
        Write-Host "  [!] ZimaOS Web UI erişilemez" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [✗] ZimaOS NAS erişilemez" -ForegroundColor Red
}

# =============================================================
# AĞ PAYLAŞIMLARI
# =============================================================
Write-Host "`n[5/5] Ağ paylaşımları..." -ForegroundColor Yellow

$shares = Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { $_.ShareType -eq 'FileSystemDirectory' }
if ($shares) {
    Write-Host "  Bu bilgisayardaki paylaşımlar:" -ForegroundColor White
    foreach ($share in $shares) {
        Write-Host "    \\$env:COMPUTERNAME\$($share.Name) → $($share.Path)" -ForegroundColor Gray
    }
} else {
    Write-Host "  Aktif paylaşım yok" -ForegroundColor Gray
}

# =============================================================
# RAPOR
# =============================================================
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  AĞ YÖNETİMİ TAMAMLANDI!                                   ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Erişim Bilgileri:" -ForegroundColor White
Write-Host "    ZimaOS Dashboard: http://192.168.1.43" -ForegroundColor Cyan
Write-Host "    ZimaOS Ollama: http://192.168.1.43:11434" -ForegroundColor Cyan
Write-Host "    Bu PC IP (Wi-Fi): 192.168.1.46" -ForegroundColor Cyan
Write-Host "    Bu PC IP (Ethernet): 192.168.1.62" -ForegroundColor Cyan
Write-Host ""
