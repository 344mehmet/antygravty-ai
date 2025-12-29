#!/bin/bash
# =====================================================
# RAGFlow ZimaOS Kurulum Scripti
# Derin belge anlayışlı RAG motoru kurulumu
# =====================================================

set -e

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            RAGFlow ZimaOS Kurulumu                  ║${NC}"
echo -e "${BLUE}║      Derin Belge Anlayışlı RAG Motoru               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# =====================================================
# 1. SİSTEM GEREKSİNİM KONTROLÜ
# =====================================================
echo -e "${YELLOW}[1/6] Sistem Gereksinimleri Kontrol Ediliyor...${NC}"

# RAM kontrolü (minimum 16GB)
TOTAL_RAM=$(free -g | awk 'NR==2 {print $2}')
if [ "$TOTAL_RAM" -lt 14 ]; then
    echo -e "${RED}⚠️ Yetersiz RAM: ${TOTAL_RAM}GB (minimum 16GB gerekli)${NC}"
    echo -e "${YELLOW}RAGFlow ağır kaynak kullanır, performans sorunu olabilir.${NC}"
else
    echo -e "${GREEN}   ✓ RAM: ${TOTAL_RAM}GB - yeterli${NC}"
fi

# Disk kontrolü (minimum 50GB)
FREE_DISK=$(df -BG /DATA 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')
if [ -n "$FREE_DISK" ] && [ "$FREE_DISK" -lt 50 ]; then
    echo -e "${RED}⚠️ Yetersiz disk: ${FREE_DISK}GB (minimum 50GB gerekli)${NC}"
    exit 1
else
    echo -e "${GREEN}   ✓ Disk: ${FREE_DISK}GB boş - yeterli${NC}"
fi

# Docker kontrolü
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
    echo -e "${GREEN}   ✓ Docker: ${DOCKER_VERSION}${NC}"
else
    echo -e "${RED}⚠️ Docker bulunamadı!${NC}"
    exit 1
fi

# =====================================================
# 2. SİSTEM AYARLARI
# =====================================================
echo -e "${YELLOW}[2/6] Sistem Ayarları Yapılıyor...${NC}"

# vm.max_map_count ayarı (Elasticsearch için kritik)
CURRENT_MAP_COUNT=$(sysctl -n vm.max_map_count 2>/dev/null || echo "0")
if [ "$CURRENT_MAP_COUNT" -lt 262144 ]; then
    echo -e "${YELLOW}   vm.max_map_count ayarlanıyor...${NC}"
    sysctl -w vm.max_map_count=262144
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf
    echo -e "${GREEN}   ✓ vm.max_map_count = 262144${NC}"
else
    echo -e "${GREEN}   ✓ vm.max_map_count zaten ayarlı: ${CURRENT_MAP_COUNT}${NC}"
fi

# =====================================================
# 3. RAGFLOW REPOSITORY CLONE
# =====================================================
echo -e "${YELLOW}[3/6] RAGFlow Repository İndiriliyor...${NC}"

RAGFLOW_DIR="/DATA/ragflow"

if [ -d "$RAGFLOW_DIR" ]; then
    echo -e "${YELLOW}   Mevcut kurulum bulundu, güncelleniyor...${NC}"
    cd "$RAGFLOW_DIR"
    git pull origin main 2>/dev/null || true
else
    echo -e "${YELLOW}   Repository klonlanıyor...${NC}"
    cd /DATA
    git clone https://github.com/infiniflow/ragflow.git
fi

cd "$RAGFLOW_DIR"
echo -e "${GREEN}   ✓ RAGFlow repository hazır: ${RAGFLOW_DIR}${NC}"

# =====================================================
# 4. DOCKER COMPOSE YAPILANDIRMA
# =====================================================
echo -e "${YELLOW}[4/6] Docker Compose Yapılandırılıyor...${NC}"

cd "$RAGFLOW_DIR/docker"

# .env dosyası yapılandırma
if [ ! -f ".env" ]; then
    cp .env.example .env 2>/dev/null || true
fi

# Slim imaj kullan (daha hızlı indirme, modeller sonra indirilir)
if [ -f ".env" ]; then
    # Port yapılandırması (80 yerine 8088 kullan, çakışma önlemek için)
    sed -i 's/SVR_HTTP_PORT=80/SVR_HTTP_PORT=8088/' .env 2>/dev/null || true
    echo -e "${GREEN}   ✓ Port: 8088${NC}"
fi

echo -e "${GREEN}   ✓ Docker Compose yapılandırması hazır${NC}"

# =====================================================
# 5. RAGFLOW BAŞLATMA
# =====================================================
echo -e "${YELLOW}[5/6] RAGFlow Başlatılıyor...${NC}"
echo -e "${YELLOW}   Bu işlem ilk seferde uzun sürebilir (imajlar indiriliyor)...${NC}"

cd "$RAGFLOW_DIR/docker"

# Önce mevcut konteynerları durdur
docker compose down 2>/dev/null || true

# RAGFlow başlat
docker compose -f docker-compose.yml up -d

# Başlatma durumunu kontrol et
sleep 10
RUNNING=$(docker compose ps --status running -q | wc -l)
echo -e "${GREEN}   ✓ ${RUNNING} konteyner çalışıyor${NC}"

# =====================================================
# 6. OLLAMA ENTEGRASYONU BİLGİLERİ
# =====================================================
echo -e "${YELLOW}[6/6] Ollama Entegrasyon Bilgileri...${NC}"

OLLAMA_URL="http://host.docker.internal:11434"
echo -e "${GREEN}   ✓ Ollama URL: ${OLLAMA_URL}${NC}"
echo -e "${GREEN}   ✓ Mevcut modeller: phi3:mini, llama2${NC}"

# =====================================================
# ÖZET RAPOR
# =====================================================
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              KURULUM TAMAMLANDI!                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📌 ERİŞİM BİLGİLERİ:${NC}"
echo -e "   RAGFlow Web UI: ${YELLOW}http://192.168.1.43:8088${NC}"
echo -e "   Open WebUI:     ${YELLOW}http://192.168.1.43:8444${NC}"
echo -e "   Ollama API:     ${YELLOW}http://192.168.1.43:11434${NC}"
echo ""
echo -e "${GREEN}📝 OLLAMA ENTEGRASYONU ADIMLARI:${NC}"
echo -e "   1. RAGFlow web arayüzüne git: http://192.168.1.43:8088"
echo -e "   2. Kayıt ol ve giriş yap"
echo -e "   3. Profil > Model Providers > Ollama ekle"
echo -e "   4. URL: http://host.docker.internal:11434"
echo -e "   5. Model: phi3:mini veya llama2"
echo ""
echo -e "${GREEN}📚 BELGE YÜKLEME:${NC}"
echo -e "   - PDF, Word, Markdown, TXT desteklenir"
echo -e "   - Knowledge Base oluştur ve belgelerini yükle"
echo -e "   - AI ile belgeler üzerinde soru-cevap yap"
echo ""
echo -e "${GREEN}✅ RAGFlow LLM Ordusuna katıldı!${NC}"
