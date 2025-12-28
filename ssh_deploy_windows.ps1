# ============================================
# Windows SSH Ağ Dağıtım Scripti
# Tüm Windows cihazları için SSH yapılandırması
# Antigravity LLM Ordusu
# ============================================

param(
    [switch]$Install,
    [switch]$Deploy,
    [switch]$Test,
    [switch]$Help
)

# Yapılandırma
$ZimaOSIP = "192.168.1.43"
$ZimaOSVPN = "10.147.11.1"
$SSHKeyName = "id_ed25519_zimaos"
$SSHDir = "$env:USERPROFILE\.ssh"

function Write-Banner {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║  Antigravity SSH Windows Dağıtım Scripti                 ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

function Write-Info { Write-Host "[BİLGİ] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[BAŞARILI] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[UYARI] $args" -ForegroundColor Yellow }
function Write-Err { Write-Host "[HATA] $args" -ForegroundColor Red }

# ============================================
# SSH KLASÖRÜ OLUŞTURMA
# ============================================
function Initialize-SSHDirectory {
    Write-Info "SSH klasörü kontrol ediliyor..."
    
    if (-not (Test-Path $SSHDir)) {
        New-Item -ItemType Directory -Path $SSHDir -Force | Out-Null
        Write-Success "SSH klasörü oluşturuldu: $SSHDir"
    } else {
        Write-Success "SSH klasörü mevcut: $SSHDir"
    }
}

# ============================================
# SSH ANAHTARI OLUŞTURMA
# ============================================
function New-SSHKey {
    $keyPath = "$SSHDir\$SSHKeyName"
    
    if (Test-Path $keyPath) {
        Write-Warn "SSH anahtarı zaten mevcut: $keyPath"
        return
    }
    
    Write-Info "Yeni SSH anahtarı oluşturuluyor..."
    $hostname = $env:COMPUTERNAME
    ssh-keygen -t ed25519 -C "antigravity@$hostname" -f $keyPath -N '""'
    Write-Success "SSH anahtarı oluşturuldu!"
}

# ============================================
# SSH CONFIG KURULUMU
# ============================================
function Set-SSHConfig {
    Write-Info "SSH config yapılandırılıyor..."
    
    $config = @"
# Antigravity LLM Ordusu Ağ Yapılandırması
# Oluşturulma: $(Get-Date -Format "yyyy-MM-dd HH:mm")

# ============================================
# ZimaOS - Ana Sunucu
# ============================================
Host zimaos
    HostName $ZimaOSIP
    User root
    Port 22
    IdentityFile ~/.ssh/$SSHKeyName
    StrictHostKeyChecking no
    UserKnownHostsFile ~/.ssh/known_hosts
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes

# ZimaOS - ZeroTier VPN
Host zimaos-vpn
    HostName $ZimaOSVPN
    User root
    Port 22
    IdentityFile ~/.ssh/$SSHKeyName
    StrictHostKeyChecking no
    ServerAliveInterval 60

# ============================================
# Windows Cihazları
# ============================================
Host windows-main
    HostName 192.168.1.46
    User win11.2025
    Port 22
    IdentityFile ~/.ssh/$SSHKeyName

Host windows-main-vpn
    HostName 10.147.11.32
    User win11.2025
    Port 22
    IdentityFile ~/.ssh/$SSHKeyName

# ============================================
# WSL (Windows Subsystem for Linux)
# ============================================
Host wsl
    HostName 172.23.252.162
    User root
    Port 22
    IdentityFile ~/.ssh/$SSHKeyName
    StrictHostKeyChecking no

# ============================================
# GitHub & GitLab
# ============================================
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/$SSHKeyName
    IdentitiesOnly yes

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/$SSHKeyName
    IdentitiesOnly yes

# ============================================
# Genel Ayarlar
# ============================================
Host *
    AddKeysToAgent yes
    IdentitiesOnly yes
    TCPKeepAlive yes
    ConnectTimeout 10
"@

    $config | Out-File -FilePath "$SSHDir\config" -Encoding UTF8 -Force
    Write-Success "SSH config hazır: $SSHDir\config"
}

# ============================================
# ZIMAOS'A ANAHTAR KOPYALAMA
# ============================================
function Deploy-SSHKey {
    Write-Info "SSH anahtarı ZimaOS'a kopyalanıyor..."
    
    $pubKeyPath = "$SSHDir\$SSHKeyName.pub"
    
    if (-not (Test-Path $pubKeyPath)) {
        Write-Err "Public key bulunamadı: $pubKeyPath"
        return
    }
    
    # Z: sürücüsüne kopyala
    if (Test-Path "Z:\Sistem\ssh-keys") {
        $pubKey = Get-Content $pubKeyPath
        $authKeysPath = "Z:\Sistem\ssh-keys\authorized_keys"
        
        # Mevcut anahtarlara ekle (duplicate kontrolü)
        if (Test-Path $authKeysPath) {
            $existing = Get-Content $authKeysPath
            if ($existing -notcontains $pubKey) {
                Add-Content -Path $authKeysPath -Value $pubKey
                Write-Success "Anahtar eklendi: authorized_keys"
            } else {
                Write-Warn "Anahtar zaten mevcut"
            }
        } else {
            $pubKey | Out-File -FilePath $authKeysPath -Encoding UTF8
            Write-Success "authorized_keys oluşturuldu"
        }
    } else {
        Write-Warn "Z:\Sistem\ssh-keys bulunamadı"
    }
}

# ============================================
# BAĞLANTI TESTİ
# ============================================
function Test-SSHConnections {
    Write-Info "SSH bağlantıları test ediliyor..."
    Write-Host ""
    
    $hosts = @(
        @{Name="ZimaOS"; IP=$ZimaOSIP; Port=22},
        @{Name="ZimaOS-VPN"; IP=$ZimaOSVPN; Port=22},
        @{Name="Windows-Main"; IP="192.168.1.46"; Port=22},
        @{Name="WSL"; IP="172.23.252.162"; Port=22}
    )
    
    foreach ($h in $hosts) {
        $result = Test-NetConnection -ComputerName $h.IP -Port $h.Port -WarningAction SilentlyContinue
        if ($result.TcpTestSucceeded) {
            Write-Success "$($h.Name) ($($h.IP):$($h.Port)) - AÇIK"
        } else {
            Write-Warn "$($h.Name) ($($h.IP):$($h.Port)) - KAPALI"
        }
    }
}

# ============================================
# PUBLIC KEY GÖSTER
# ============================================
function Show-PublicKey {
    $pubKeyPath = "$SSHDir\$SSHKeyName.pub"
    
    if (Test-Path $pubKeyPath) {
        Write-Host ""
        Write-Info "Public Key (diğer cihazlara ekleyin):"
        Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Get-Content $pubKeyPath
        Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host ""
    }
}

# ============================================
# YARDIM
# ============================================
function Show-Help {
    Write-Banner
    Write-Host "Kullanım:" -ForegroundColor Yellow
    Write-Host "  .\ssh_deploy_windows.ps1 -Install  : SSH kurulumu yap"
    Write-Host "  .\ssh_deploy_windows.ps1 -Deploy   : Anahtarı ZimaOS'a kopyala"
    Write-Host "  .\ssh_deploy_windows.ps1 -Test     : Bağlantıları test et"
    Write-Host "  .\ssh_deploy_windows.ps1 -Help     : Bu yardım mesajı"
    Write-Host ""
    Write-Host "SSH Komutları:" -ForegroundColor Yellow
    Write-Host "  ssh zimaos        # ZimaOS'a bağlan"
    Write-Host "  ssh zimaos-vpn    # VPN üzerinden bağlan"
    Write-Host "  ssh wsl           # WSL'e bağlan"
    Write-Host ""
}

# ============================================
# ANA PROGRAM
# ============================================
if ($Help) {
    Show-Help
} elseif ($Install) {
    Write-Banner
    Initialize-SSHDirectory
    New-SSHKey
    Set-SSHConfig
    Show-PublicKey
    Write-Success "SSH kurulumu tamamlandı!"
} elseif ($Deploy) {
    Write-Banner
    Deploy-SSHKey
    Write-Success "SSH anahtarı dağıtıldı!"
} elseif ($Test) {
    Write-Banner
    Test-SSHConnections
} else {
    # Varsayılan: Tam kurulum
    Write-Banner
    Initialize-SSHDirectory
    New-SSHKey
    Set-SSHConfig
    Deploy-SSHKey
    Show-PublicKey
    Test-SSHConnections
    Write-Host ""
    Write-Success "SSH tam kurulum tamamlandı!"
}
