#!/bin/bash
# ============================================
# Ağ Genelinde SSH Dağıtım Scripti
# Tüm cihazlarda SSH yapılandırması
# Antigravity LLM Ordusu
# ============================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Antigravity SSH Ağ Dağıtım Scripti                        ║"
echo "╚════════════════════════════════════════════════════════════╝"

# Yapılandırma
ZIMAOS_IP="192.168.1.43"
ZIMAOS_VPN="10.147.11.1"
SSH_KEY_NAME="id_ed25519_zimaos"

# Renk tanımları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[BİLGİ]${NC} $1"; }
log_success() { echo -e "${GREEN}[BAŞARILI]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[UYARI]${NC} $1"; }
log_error() { echo -e "${RED}[HATA]${NC} $1"; }

# ============================================
# 1. SSH KLASÖRÜ OLUŞTURMA
# ============================================
setup_ssh_directory() {
    log_info "SSH klasörü oluşturuluyor..."
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    log_success "SSH klasörü hazır: ~/.ssh"
}

# ============================================
# 2. SSH ANAHTARI OLUŞTURMA
# ============================================
generate_ssh_key() {
    if [ -f ~/.ssh/$SSH_KEY_NAME ]; then
        log_warning "SSH anahtarı zaten mevcut: ~/.ssh/$SSH_KEY_NAME"
        return
    fi
    
    log_info "Yeni SSH anahtarı oluşturuluyor..."
    ssh-keygen -t ed25519 -C "antigravity@$(hostname)" -f ~/.ssh/$SSH_KEY_NAME -N ""
    log_success "SSH anahtarı oluşturuldu!"
}

# ============================================
# 3. SSH CONFIG KURULUMU
# ============================================
setup_ssh_config() {
    log_info "SSH config yapılandırılıyor..."
    
    cat > ~/.ssh/config << 'EOF'
# Antigravity LLM Ordusu Ağ Yapılandırması

# ZimaOS - Ana Sunucu
Host zimaos
    HostName 192.168.1.43
    User root
    Port 22
    IdentityFile ~/.ssh/id_ed25519_zimaos
    StrictHostKeyChecking no
    ServerAliveInterval 60

# ZimaOS - VPN
Host zimaos-vpn
    HostName 10.147.11.1
    User root
    Port 22
    IdentityFile ~/.ssh/id_ed25519_zimaos
    StrictHostKeyChecking no

# Windows Ana
Host windows-main
    HostName 192.168.1.46
    User win11.2025
    Port 22
    IdentityFile ~/.ssh/id_ed25519_zimaos

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_zimaos

# Genel
Host *
    AddKeysToAgent yes
    IdentitiesOnly yes
    TCPKeepAlive yes
    ConnectTimeout 10
EOF

    chmod 600 ~/.ssh/config
    log_success "SSH config hazır!"
}

# ============================================
# 4. AUTHORIZED_KEYS GÜNCELLEME
# ============================================
setup_authorized_keys() {
    log_info "Authorized keys güncelleniyor..."
    
    # ZimaOS'tan public key'i al
    if [ -f /DATA/Sistem/ssh-keys/authorized_keys ]; then
        cat /DATA/Sistem/ssh-keys/authorized_keys >> ~/.ssh/authorized_keys
        sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        log_success "Authorized keys güncellendi!"
    else
        log_warning "ZimaOS authorized_keys bulunamadı"
    fi
}

# ============================================
# 5. SSH SERVİSİ KONTROLÜ
# ============================================
check_ssh_service() {
    log_info "SSH servisi kontrol ediliyor..."
    
    if command -v systemctl &> /dev/null; then
        if systemctl is-active --quiet sshd; then
            log_success "SSH servisi çalışıyor"
        else
            log_warning "SSH servisi başlatılıyor..."
            systemctl enable sshd
            systemctl start sshd
        fi
    elif command -v service &> /dev/null; then
        service ssh status || service ssh start
    fi
}

# ============================================
# 6. BAĞLANTI TESTİ
# ============================================
test_connections() {
    log_info "Bağlantılar test ediliyor..."
    
    # ZimaOS testi
    if ssh -o ConnectTimeout=5 -o BatchMode=yes zimaos "echo ok" 2>/dev/null; then
        log_success "ZimaOS bağlantısı başarılı!"
    else
        log_warning "ZimaOS bağlantısı başarısız (şifre gerekebilir)"
    fi
}

# ============================================
# ANA PROGRAM
# ============================================
main() {
    echo ""
    log_info "Kurulum başlıyor..."
    echo ""
    
    setup_ssh_directory
    generate_ssh_key
    setup_ssh_config
    setup_authorized_keys
    check_ssh_service
    
    echo ""
    log_info "Public Key (diğer cihazlara ekleyin):"
    echo "----------------------------------------"
    cat ~/.ssh/${SSH_KEY_NAME}.pub 2>/dev/null || log_warning "Public key bulunamadı"
    echo "----------------------------------------"
    echo ""
    
    test_connections
    
    echo ""
    log_success "SSH kurulumu tamamlandı!"
    echo ""
    echo "Kullanım:"
    echo "  ssh zimaos        # ZimaOS'a bağlan"
    echo "  ssh zimaos-vpn    # VPN üzerinden bağlan"
    echo "  ssh windows-main  # Windows'a bağlan"
}

main "$@"
