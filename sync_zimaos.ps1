# ============================================
# Windows - ZimaOS Senkronizasyon Scripti
# LLM Ordusu Merkezi Yönetim Sistemi
# Dil: Türkçe
# ============================================

param(
    [switch]$Backup,
    [switch]$Sync,
    [switch]$Status,
    [switch]$Help
)

# Yapılandırma
$ZimaOSIP = "192.168.1.43"
$ZimaDrive = "Z:"
$LocalBackupPath = "$env:USERPROFILE\ZimaOS-Backup"
$LogPath = "$env:USERPROFILE\ZimaOS-Backup\logs"

# Renk fonksiyonları
function Write-Info { Write-Host "[BİLGİ] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[BAŞARILI] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[UYARI] $args" -ForegroundColor Yellow }
function Write-Err { Write-Host "[HATA] $args" -ForegroundColor Red }

# Banner
function Show-Banner {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║  ZimaOS Senkronizasyon ve Yedekleme Aracı               ║" -ForegroundColor Blue
    Write-Host "║  LLM Ordusu Merkezi Yönetim Sistemi                     ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

# Yardım
function Show-Help {
    Show-Banner
    Write-Host "Kullanım:" -ForegroundColor Yellow
    Write-Host "  .\sync_zimaos.ps1 -Backup    : ZimaOS'tan yerel yedek al"
    Write-Host "  .\sync_zimaos.ps1 -Sync      : Dosyaları senkronize et"
    Write-Host "  .\sync_zimaos.ps1 -Status    : Bağlantı ve disk durumu"
    Write-Host "  .\sync_zimaos.ps1 -Help      : Bu yardım mesajı"
    Write-Host ""
}

# ZimaOS bağlantı kontrolü
function Test-ZimaConnection {
    Write-Info "ZimaOS bağlantısı kontrol ediliyor..."
    
    $ping = Test-Connection -ComputerName $ZimaOSIP -Count 1 -Quiet
    if ($ping) {
        Write-Success "ZimaOS erişilebilir: $ZimaOSIP"
        return $true
    } else {
        Write-Err "ZimaOS'a erişilemiyor: $ZimaOSIP"
        return $false
    }
}

# Z: sürücü kontrolü
function Test-ZimaDrive {
    if (Test-Path $ZimaDrive) {
        Write-Success "Z: sürücüsü bağlı"
        return $true
    } else {
        Write-Warn "Z: sürücüsü bağlı değil"
        Write-Info "Bağlantı kuruluyor..."
        
        # SMB bağlantısı
        try {
            net use Z: "\\$ZimaOSIP\ZimaOS-HD" /persistent:yes
            Write-Success "Z: sürücüsü bağlandı"
            return $true
        } catch {
            Write-Err "Bağlantı kurulamadı: $_"
            return $false
        }
    }
}

# Durum kontrolü
function Get-ZimaStatus {
    Show-Banner
    Write-Info "Sistem Durumu Kontrolü"
    Write-Host ""
    
    # Bağlantı testi
    Test-ZimaConnection | Out-Null
    Test-ZimaDrive | Out-Null
    
    Write-Host ""
    Write-Info "Disk Kullanımı:"
    
    if (Test-Path $ZimaDrive) {
        $disk = Get-PSDrive Z
        $usedGB = [math]::Round($disk.Used / 1GB, 2)
        $freeGB = [math]::Round($disk.Free / 1GB, 2)
        $totalGB = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
        $usedPercent = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 1)
        
        Write-Host "  Toplam: $totalGB GB"
        Write-Host "  Kullanılan: $usedGB GB ($usedPercent%)"
        Write-Host "  Boş: $freeGB GB"
    }
    
    Write-Host ""
    Write-Info "Klasör Yapısı:"
    if (Test-Path "$ZimaDrive\LLM-Ordusu") {
        Write-Success "  LLM-Ordusu klasörü mevcut"
    }
    if (Test-Path "$ZimaDrive\Yonetim-Merkezi") {
        Write-Success "  Yonetim-Merkezi klasörü mevcut"
    }
    if (Test-Path "$ZimaDrive\Depolama") {
        Write-Success "  Depolama klasörü mevcut"
    }
    if (Test-Path "$ZimaDrive\Sistem") {
        Write-Success "  Sistem klasörü mevcut"
    }
    
    Write-Host ""
    Write-Info "Portları kontrol ediliyor..."
    $ports = @(80, 443, 9000, 11434, 3000, 5678, 3001)
    foreach ($port in $ports) {
        $result = Test-NetConnection -ComputerName $ZimaOSIP -Port $port -WarningAction SilentlyContinue
        if ($result.TcpTestSucceeded) {
            Write-Success "  Port $port açık"
        }
    }
}

# Yedekleme
function Start-ZimaBackup {
    Show-Banner
    Write-Info "Yedekleme başlatılıyor..."
    
    if (-not (Test-ZimaConnection)) { return }
    if (-not (Test-ZimaDrive)) { return }
    
    # Yedek klasörü oluştur
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $backupDir = "$LocalBackupPath\backup_$timestamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    
    Write-Info "Yedek konumu: $backupDir"
    
    # Kritik klasörleri yedekle
    $foldersToBackup = @(
        "Yonetim-Merkezi\docker-compose",
        "Yonetim-Merkezi\configs",
        "Sistem\ssh-keys",
        "LLM-Ordusu\agents"
    )
    
    foreach ($folder in $foldersToBackup) {
        $source = "$ZimaDrive\$folder"
        $dest = "$backupDir\$folder"
        
        if (Test-Path $source) {
            Write-Info "Yedekleniyor: $folder"
            robocopy $source $dest /MIR /R:3 /W:5 /NP /NFL /NDL | Out-Null
            Write-Success "Tamamlandı: $folder"
        }
    }
    
    Write-Host ""
    Write-Success "Yedekleme tamamlandı: $backupDir"
}

# Senkronizasyon
function Start-ZimaSync {
    Show-Banner
    Write-Info "Senkronizasyon başlatılıyor..."
    
    if (-not (Test-ZimaConnection)) { return }
    if (-not (Test-ZimaDrive)) { return }
    
    # Yerel dosyaları ZimaOS'a kopyala
    $localSyncDir = "$env:USERPROFILE\Desktop\antygravty google id"
    
    if (Test-Path "$localSyncDir\docker-compose.yml") {
        Write-Info "Docker Compose dosyası senkronize ediliyor..."
        Copy-Item "$localSyncDir\docker-compose.yml" -Destination "$ZimaDrive\Yonetim-Merkezi\docker-compose\" -Force
        Write-Success "docker-compose.yml güncellendi"
    }
    
    if (Test-Path "$localSyncDir\zimaos-setup.sh") {
        Write-Info "Kurulum scripti senkronize ediliyor..."
        Copy-Item "$localSyncDir\zimaos-setup.sh" -Destination "$ZimaDrive\Yonetim-Merkezi\scripts\" -Force
        Write-Success "zimaos-setup.sh güncellendi"
    }
    
    Write-Host ""
    Write-Success "Senkronizasyon tamamlandı!"
}

# Ana program
if ($Help) {
    Show-Help
} elseif ($Status) {
    Get-ZimaStatus
} elseif ($Backup) {
    Start-ZimaBackup
} elseif ($Sync) {
    Start-ZimaSync
} else {
    Show-Help
}
