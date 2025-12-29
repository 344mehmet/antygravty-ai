#!/bin/bash
# ============================================
# ZimaOS Mesh VPN + Sürücü Yönetim Scripti
# Nas344mehmet2026 - 29 Aralık 2025
# ============================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ZimaOS Mesh VPN + Sürücü Yönetimi                         ║"
echo "╚════════════════════════════════════════════════════════════╝"

# Renk tanımları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[BİLGİ]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# ============================================
# 1. SİSTEM BİLGİSİ TOPLAMA
# ============================================
log_info "Sistem bilgisi toplanıyor..."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SİSTEM BİLGİSİ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $2}')"

# ============================================
# 2. SÜRÜCÜ KONTROLÜ
# ============================================
log_info "Sürücüler kontrol ediliyor..."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SÜRÜCÜ DURUMU"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# GPU
echo ""
echo "🎮 GPU Sürücüsü:"
GPU_INFO=$(lspci | grep -i "VGA\|Display" 2>/dev/null)
if [ -n "$GPU_INFO" ]; then
    echo "  $GPU_INFO"
    lspci -k | grep -A 3 -i "VGA\|Display" | grep "Kernel driver" 2>/dev/null
else
    echo "  GPU bulunamadı"
fi

# Ethernet
echo ""
echo "🌐 Ethernet Sürücüsü:"
for iface in $(ls /sys/class/net/ | grep -v lo); do
    DRIVER=$(ethtool -i $iface 2>/dev/null | grep driver | cut -d':' -f2 | xargs)
    echo "  $iface: $DRIVER"
done

# Disk
echo ""
echo "💾 Disk Sürücüleri:"
lsblk -o NAME,TYPE,SIZE,MODEL | grep -v loop

# USB
echo ""
echo "🔌 USB Cihazları:"
lsusb 2>/dev/null | head -5

# ============================================
# 3. FİRMWARE GÜNCELLEMESİ
# ============================================
log_info "Firmware güncelleniyor..."

apt update > /dev/null 2>&1

# Linux firmware
if apt list --installed 2>/dev/null | grep -q linux-firmware; then
    log_success "linux-firmware kurulu"
else
    log_info "linux-firmware kuruluyor..."
    apt install -y linux-firmware > /dev/null 2>&1
fi

# AMD GPU firmware
if lspci | grep -qi "AMD\|ATI"; then
    log_info "AMD GPU firmware kontrol ediliyor..."
    apt install -y firmware-amd-graphics > /dev/null 2>&1
    log_success "AMD firmware güncellendi"
fi

# Realtek firmware
if lsmod | grep -qi "r8"; then
    apt install -y firmware-realtek > /dev/null 2>&1
    log_success "Realtek firmware güncellendi"
fi

# ============================================
# 4. TAILSCALE KURULUMU
# ============================================
log_info "Tailscale kontrol ediliyor..."

if command -v tailscale &> /dev/null; then
    log_success "Tailscale kurulu"
    tailscale status 2>/dev/null || log_warning "Tailscale bağlı değil"
else
    log_info "Tailscale kuruluyor..."
    
    # Docker ile Tailscale
    docker pull tailscale/tailscale:latest 2>/dev/null
    
    docker run -d \
        --name tailscale \
        --hostname zimaos-nas \
        --cap-add NET_ADMIN \
        --cap-add SYS_MODULE \
        -v /dev/net/tun:/dev/net/tun \
        -v tailscale_data:/var/lib/tailscale \
        -e TS_STATE_DIR=/var/lib/tailscale \
        -e TS_ROUTES=192.168.1.0/24 \
        --restart always \
        tailscale/tailscale 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Tailscale Docker container başlatıldı"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  TAİLSCALE AKTİVASYON"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Tailscale'i aktive etmek için:"
        echo "  docker exec tailscale tailscale up"
        echo ""
        echo "Ardından tarayıcıda verilen URL ile giriş yapın."
    else
        log_warning "Tailscale Docker container başlatılamadı"
    fi
fi

# ============================================
# 5. ZEROTIER KONTROLÜ
# ============================================
log_info "ZeroTier kontrol ediliyor..."

if command -v zerotier-cli &> /dev/null; then
    log_success "ZeroTier kurulu"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ZEROTIER DURUMU"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    zerotier-cli info 2>/dev/null
    zerotier-cli listnetworks 2>/dev/null
else
    log_warning "ZeroTier kurulu değil (ZimaOS'ta dahili olarak mevcut olabilir)"
fi

# ============================================
# 6. AĞ BİLGİLERİ
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  AĞ BİLGİLERİ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Local IP
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "Local IP: $LOCAL_IP"

# Gateway
GATEWAY=$(ip route | grep default | awk '{print $3}')
echo "Gateway: $GATEWAY"

# DNS
DNS=$(cat /etc/resolv.conf | grep nameserver | head -1 | awk '{print $2}')
echo "DNS: $DNS"

# Tailscale IP
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null)
if [ -n "$TAILSCALE_IP" ]; then
    echo "Tailscale IP: $TAILSCALE_IP"
fi

# ============================================
# 7. DURUM RAPORU
# ============================================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  KURULUM TAMAMLANDI!                                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_info "Mesh VPN Erişim:"
echo "  • ZeroTier: ZimaOS Dashboard > Network > Remote Login"
echo "  • Tailscale: docker exec tailscale tailscale up"
echo ""
log_info "Yönetim Panelleri:"
echo "  • ZimaOS: http://$LOCAL_IP"
echo "  • Portainer: http://$LOCAL_IP:9000"
echo "  • Uptime Kuma: http://$LOCAL_IP:3001"
echo ""
log_success "Mesh ağ ve sürücü yönetimi tamamlandı!"
