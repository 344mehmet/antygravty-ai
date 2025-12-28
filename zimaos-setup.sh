#!/bin/bash
# ============================================
# ZimaOS AMD GPU (RX560/RX580) Kurulum Scripti
# LLM Ordusu Merkezi Yönetim Sistemi
# Dil: Türkçe
# ============================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ZimaOS AMD GPU + LLM Merkezi Kurulum Scripti              ║"
echo "║  AMD RX560/RX580 8GB GPU Desteği                           ║"
echo "╚════════════════════════════════════════════════════════════╝"

# Renk tanımları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[BİLGİ]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[BAŞARILI]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[UYARI]${NC} $1"
}

log_error() {
    echo -e "${RED}[HATA]${NC} $1"
}

# ============================================
# 1. SİSTEM GÜNCELLEMESİ
# ============================================
log_info "Sistem güncelleniyor..."
apt-get update && apt-get upgrade -y

# ============================================
# 2. AMD GPU SÜRÜCÜ KONTROLÜ
# ============================================
log_info "AMD GPU kontrol ediliyor..."

# GPU bilgisini al
GPU_INFO=$(lspci | grep -i "VGA\|Display" | grep -i "AMD\|ATI")
if [ -z "$GPU_INFO" ]; then
    log_error "AMD GPU bulunamadı!"
    exit 1
fi
log_success "AMD GPU tespit edildi: $GPU_INFO"

# ============================================
# 3. ROCm KURULUMU (AMD GPU için)
# ============================================
log_info "ROCm desteği kontrol ediliyor..."

# Kernel modülleri
modprobe amdgpu 2>/dev/null || log_warning "amdgpu modülü yüklenemedi"

# /dev/kfd ve /dev/dri kontrolü
if [ -e /dev/kfd ]; then
    log_success "/dev/kfd mevcut"
else
    log_warning "/dev/kfd bulunamadı - GPU compute desteği sınırlı olabilir"
fi

if [ -d /dev/dri ]; then
    log_success "/dev/dri mevcut"
    ls -la /dev/dri/
else
    log_warning "/dev/dri bulunamadı"
fi

# ============================================
# 4. DOCKER KURULUMU/KONTROLÜ
# ============================================
log_info "Docker kontrol ediliyor..."

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    log_success "Docker kurulu: $DOCKER_VERSION"
else
    log_info "Docker kuruluyor..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    log_success "Docker kuruldu!"
fi

# Docker Compose kontrolü
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    log_success "Docker Compose mevcut"
else
    log_info "Docker Compose kuruluyor..."
    apt-get install -y docker-compose-plugin
fi

# ============================================
# 5. KULLANICI GRUPLARI
# ============================================
log_info "Kullanıcı grupları ayarlanıyor..."
usermod -aG docker root 2>/dev/null
usermod -aG video root 2>/dev/null
usermod -aG render root 2>/dev/null

# ============================================
# 6. KLASÖR YAPISI OLUŞTURMA
# ============================================
log_info "Klasör yapısı oluşturuluyor..."

DIRS=(
    "/DATA/LLM-Ordusu/models/ollama"
    "/DATA/LLM-Ordusu/models/huggingface"
    "/DATA/LLM-Ordusu/databases/postgresql"
    "/DATA/LLM-Ordusu/databases/mongodb"
    "/DATA/LLM-Ordusu/databases/vector-db"
    "/DATA/LLM-Ordusu/agents/defensive"
    "/DATA/LLM-Ordusu/agents/management"
    "/DATA/LLM-Ordusu/agents/automation"
    "/DATA/LLM-Ordusu/github-repos"
    "/DATA/LLM-Ordusu/logs"
    "/DATA/Yonetim-Merkezi/docker-compose"
    "/DATA/Yonetim-Merkezi/configs/uptime-kuma"
    "/DATA/Yonetim-Merkezi/configs/nginx"
    "/DATA/Yonetim-Merkezi/scripts"
    "/DATA/Yonetim-Merkezi/backups"
    "/DATA/Sistem/ssh-keys"
    "/DATA/Sistem/certs"
    "/DATA/Sistem/temp"
)

for dir in "${DIRS[@]}"; do
    mkdir -p "$dir"
    log_success "Oluşturuldu: $dir"
done

# ============================================
# 7. SSH ANAHTARI KURULUMU
# ============================================
log_info "SSH anahtarları ayarlanıyor..."

if [ -f "/DATA/Sistem/ssh-keys/authorized_keys" ]; then
    mkdir -p ~/.ssh
    cat "/DATA/Sistem/ssh-keys/authorized_keys" >> ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys
    log_success "SSH anahtarları kuruldu!"
fi

# ============================================
# 8. DOCKER COMPOSE BAŞLATMA
# ============================================
log_info "Docker servisleri başlatılıyor..."

cd /DATA/Yonetim-Merkezi/docker-compose

if [ -f "docker-compose.yml" ]; then
    # Önce mevcut konteynerleri durdur
    docker compose down 2>/dev/null || true
    
    # Servisleri başlat
    docker compose up -d
    
    log_success "Docker servisleri başlatıldı!"
else
    log_warning "docker-compose.yml bulunamadı!"
    log_info "Dosyayı Windows'tan kopyalayın: Z:\Yonetim-Merkezi\docker-compose\docker-compose.yml"
fi

# ============================================
# 9. OLLAMA MODEL İNDİRME
# ============================================
log_info "Ollama modelleri indiriliyor..."

# Ollama'nın hazır olmasını bekle
sleep 10

# Temel modelleri indir
docker exec ollama-amd ollama pull llama2:7b 2>/dev/null || log_warning "llama2:7b indirilemedi"
docker exec ollama-amd ollama pull mistral:7b 2>/dev/null || log_warning "mistral:7b indirilemedi"
docker exec ollama-amd ollama pull codellama:7b 2>/dev/null || log_warning "codellama:7b indirilemedi"

# ============================================
# 10. DURUM RAPORU
# ============================================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  KURULUM TAMAMLANDI!                                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_info "Servis Durumları:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
log_info "Erişim Adresleri:"
echo "  • Portainer:        https://192.168.1.43:9443"
echo "  • Open WebUI:       http://192.168.1.43:3000"
echo "  • Ollama API:       http://192.168.1.43:11434"
echo "  • n8n Otomasyon:    http://192.168.1.43:5678"
echo "  • Uptime Kuma:      http://192.168.1.43:3001"
echo "  • Flowise:          http://192.168.1.43:3002"
echo "  • ChromaDB:         http://192.168.1.43:8000"
echo "  • Nginx Proxy:      http://192.168.1.43:81"
echo ""
log_info "Varsayılan Giriş Bilgileri:"
echo "  • Kullanıcı: admin"
echo "  • Şifre: Antigravity2025!"
echo ""
log_success "LLM Ordusu Merkezi Yönetim Sistemi hazır!"
