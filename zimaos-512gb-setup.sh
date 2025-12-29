#!/bin/bash
# ============================================
# ZimaOS 512GB HDD Yapılandırma Scripti
# Kullanıcı: Nas344mehmet2026
# 29 Aralık 2025
# ============================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ZimaOS 512GB HDD - LLM Ordusu Yapılandırması              ║"
echo "║  Kullanıcı: Nas344mehmet2026                               ║"
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
# 1. ROOT ŞİFRESİ AYARLAMA
# ============================================
log_info "Root şifresi ayarlanıyor..."
echo "root:1234567890" | chpasswd
log_success "Root şifresi: 1234567890"

# ============================================
# 2. SİSTEM BİLGİSİ
# ============================================
log_info "Sistem bilgisi alınıyor..."
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Disk: $(df -h / | tail -1 | awk '{print $2}')"

# ============================================
# 3. KLASÖR YAPISI (512GB için optimize)
# ============================================
log_info "512GB için klasör yapısı oluşturuluyor..."

DIRS=(
    "/DATA/LLM-Ordusu/models/ollama"
    "/DATA/LLM-Ordusu/models/huggingface"
    "/DATA/LLM-Ordusu/databases/postgresql"
    "/DATA/LLM-Ordusu/databases/mongodb"
    "/DATA/LLM-Ordusu/databases/vector-db"
    "/DATA/LLM-Ordusu/agents"
    "/DATA/LLM-Ordusu/logs"
    "/DATA/Yonetim-Merkezi/docker-compose"
    "/DATA/Yonetim-Merkezi/configs"
    "/DATA/Yonetim-Merkezi/backups"
    "/DATA/Orkestra-Bot/exports"
    "/DATA/Orkestra-Bot/articles"
    "/DATA/Sistem/ssh-keys"
    "/DATA/Sistem/certs"
)

for dir in "${DIRS[@]}"; do
    mkdir -p "$dir"
    log_success "Oluşturuldu: $dir"
done

# ============================================
# 4. DOCKER KURULUMU
# ============================================
log_info "Docker kontrol ediliyor..."

if command -v docker &> /dev/null; then
    log_success "Docker kurulu: $(docker --version)"
else
    log_info "Docker kuruluyor..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

# ============================================
# 5. KULLANICI GRUPLARI
# ============================================
log_info "Kullanıcı grupları ayarlanıyor..."
usermod -aG docker root 2>/dev/null
usermod -aG video root 2>/dev/null
usermod -aG render root 2>/dev/null
log_success "Gruplar ayarlandı"

# ============================================
# 6. DOCKER COMPOSE DOSYASI (GPU DESTEKLİ)
# ============================================
log_info "GPU destekli Docker Compose oluşturuluyor..."

cat > /DATA/Yonetim-Merkezi/docker-compose/docker-compose.yml << 'EOF'
version: '3.8'

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    ports:
      - "9000:9000"
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

  rocm-host:
    image: docker.io/rocm/dev-ubuntu-22.04:5.7.1-complete
    container_name: rocm-host
    restart: always
    devices:
      - /dev/kfd:/dev/kfd
      - /dev/dri:/dev/dri
    group_add:
      - video
      - render
    volumes:
      - rocm_libs:/opt/rocm
    command: ["sleep", "infinity"]

  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: always
    ports:
      - "11434:11434"
    devices:
      - /dev/kfd:/dev/kfd
      - /dev/dri:/dev/dri
    group_add:
      - video
      - render
    environment:
      - HIP_PATH=/opt/rocm
      - LD_LIBRARY_PATH=/opt/rocm/lib
      - HSA_OVERRIDE_GFX_VERSION=8.0.3
    volumes:
      - /DATA/LLM-Ordusu/models/ollama:/root/.ollama
    volumes_from:
      - rocm-host:ro
    depends_on:
      - rocm-host
    deploy:
      resources:
        limits:
          memory: 12G

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: always
    ports:
      - "3000:8080"
    volumes:
      - open_webui_data:/app/backend/data
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
    depends_on:
      - ollama

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: always
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=Nas344mehmet2026
      - N8N_BASIC_AUTH_PASSWORD=1234567890

  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    restart: always
    ports:
      - "3001:3001"
    volumes:
      - uptime_kuma_data:/app/data

  postgres:
    image: postgres:15
    container_name: postgres
    restart: always
    ports:
      - "5432:5432"
    volumes:
      - /DATA/LLM-Ordusu/databases/postgresql:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=Nas344mehmet2026
      - POSTGRES_PASSWORD=1234567890
      - POSTGRES_DB=llm_ordusu

  chromadb:
    image: chromadb/chroma:latest
    container_name: chromadb
    restart: always
    ports:
      - "8000:8000"
    volumes:
      - /DATA/LLM-Ordusu/databases/vector-db:/chroma/chroma

volumes:
  portainer_data:
  rocm_libs:
  open_webui_data:
  n8n_data:
  uptime_kuma_data:
EOF

log_success "docker-compose.yml oluşturuldu"

# ============================================
# 7. SERVİSLERİ BAŞLAT
# ============================================
log_info "Docker servisleri başlatılıyor..."

cd /DATA/Yonetim-Merkezi/docker-compose
docker compose up -d

log_success "Tüm servisler başlatıldı!"

# ============================================
# 8. OLLAMA MODEL İNDİRME
# ============================================
log_info "Ollama modeli indiriliyor (qwen2.5:0.5b)..."
sleep 15
docker exec ollama ollama pull qwen2.5:0.5b

# ============================================
# 9. DURUM RAPORU
# ============================================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  KURULUM TAMAMLANDI!                                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_info "Servis Durumları:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ERİŞİM ADRESLERİ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  • Portainer:    http://192.168.1.43:9000"
echo "  • Open WebUI:   http://192.168.1.43:3000"
echo "  • Ollama API:   http://192.168.1.43:11434"
echo "  • n8n:          http://192.168.1.43:5678"
echo "  • Uptime Kuma:  http://192.168.1.43:3001"
echo "  • ChromaDB:     http://192.168.1.43:8000"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  GİRİŞ BİLGİLERİ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  • Kullanıcı: Nas344mehmet2026"
echo "  • Şifre:     1234567890"
echo ""
log_success "ZimaOS 512GB LLM Ordusu Merkezi hazır!"
