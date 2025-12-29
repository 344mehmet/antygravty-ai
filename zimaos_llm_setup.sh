#!/bin/bash
#
# ZimaOS LLM ORDUSU KURULUM SCRIPTİ
# 344Mehmet - 29 Aralık 2025
#
# Kullanım: curl -sSL https://raw.githubusercontent.com/344mehmet/antygravty-ai/main/zimaos_llm_setup.sh | bash
#

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  ZimaOS LLM ORDUSU KURULUMU                               ║"
echo "║  Ollama + Open WebUI + MCP                                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Değişkenler
OLLAMA_PORT=11434
WEBUI_PORT=3000
DATA_DIR="/DATA/llm-ordusu"
MODELS_DIR="${DATA_DIR}/models"
GITHUB_REPO="https://github.com/344mehmet/antygravty-ai.git"

# Renk tanımları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. Dizinleri oluştur
log_info "Dizinler oluşturuluyor..."
mkdir -p "${DATA_DIR}"
mkdir -p "${MODELS_DIR}"
mkdir -p "${DATA_DIR}/config"
mkdir -p "${DATA_DIR}/webui"

# 2. Docker kontrolü
log_info "Docker kontrol ediliyor..."
if ! command -v docker &> /dev/null; then
    log_error "Docker bulunamadı! ZimaOS'ta Docker kurulu olmalı."
    exit 1
fi

# 3. Ollama Container
log_info "Ollama container başlatılıyor..."
docker pull ollama/ollama:latest

docker stop ollama 2>/dev/null || true
docker rm ollama 2>/dev/null || true

docker run -d \
    --name ollama \
    --restart unless-stopped \
    -p ${OLLAMA_PORT}:11434 \
    -v "${MODELS_DIR}:/root/.ollama" \
    ollama/ollama:latest

log_info "Ollama başlatıldı (port: ${OLLAMA_PORT})"

# 4. Ollama'nın başlamasını bekle
log_info "Ollama hazır olana kadar bekleniyor..."
sleep 10

# 5. LLM Modelleri indir
log_info "LLM modelleri indiriliyor..."

# Küçük ve hızlı modeller
docker exec ollama ollama pull qwen2.5:0.5b
docker exec ollama ollama pull qwen2.5:1.5b
docker exec ollama ollama pull phi3:mini
docker exec ollama ollama pull nomic-embed-text

log_info "Modeller indirildi!"

# 6. Özel 344mehmet-assistant modeli
log_info "Özel 344mehmet-assistant modeli oluşturuluyor..."

cat > "${DATA_DIR}/Modelfile" << 'MODELFILE'
FROM qwen2.5:1.5b

SYSTEM """
Sen 344Mehmet'in kişisel AI asistanısın. LLM Ordusu'nun başkanısın.

GÖREVLER:
- Yazılım geliştirme ve kod yazma
- Finansal analiz ve trading stratejileri
- Telegram bot yönetimi
- ZimaOS ve sistem yönetimi
- MQL5 Expert Advisor geliştirme

KURALLAR:
1. Türkçe cevap ver
2. Kısa, net ve doğru bilgi ver
3. Emin olmadığın konularda "Bilmiyorum" de
4. Kod örnekleri ver
5. Finansal konularda dikkatli ol ve risk uyarısı yap

BİLGİLER:
- OKX TR ve Binance TR borsalarını kullanıyorsun
- ZimaOS NAS: 192.168.1.43
- Ollama API: localhost:11434
"""

PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER num_ctx 4096
MODELFILE

docker cp "${DATA_DIR}/Modelfile" ollama:/tmp/Modelfile
docker exec ollama ollama create 344mehmet-assistant -f /tmp/Modelfile

log_info "344mehmet-assistant modeli oluşturuldu!"

# 7. Open WebUI kurulumu
log_info "Open WebUI başlatılıyor..."

docker pull ghcr.io/open-webui/open-webui:main

docker stop open-webui 2>/dev/null || true
docker rm open-webui 2>/dev/null || true

docker run -d \
    --name open-webui \
    --restart unless-stopped \
    -p ${WEBUI_PORT}:8080 \
    -e OLLAMA_BASE_URL=http://host.docker.internal:${OLLAMA_PORT} \
    --add-host=host.docker.internal:host-gateway \
    -v "${DATA_DIR}/webui:/app/backend/data" \
    ghcr.io/open-webui/open-webui:main

log_info "Open WebUI başlatıldı (port: ${WEBUI_PORT})"

# 8. GitHub repo klonla
log_info "GitHub repo klonlanıyor..."
cd "${DATA_DIR}"
if [ -d "antygravty-ai" ]; then
    cd antygravty-ai && git pull
else
    git clone "${GITHUB_REPO}"
fi

# 9. MCP yapılandırması
log_info "MCP yapılandırması oluşturuluyor..."

cat > "${DATA_DIR}/config/mcp_config.json" << 'MCP_CONFIG'
{
    "mcpServers": {
        "filesystem": {
            "command": "npx",
            "args": ["-y", "@anthropic-ai/claude-code-mcp", "filesystem", "--allow-dir", "/DATA"]
        },
        "ollama": {
            "command": "curl",
            "args": ["-s", "http://localhost:11434/api/tags"]
        },
        "memory": {
            "command": "npx",
            "args": ["-y", "@anthropic-ai/claude-code-mcp", "memory"]
        }
    }
}
MCP_CONFIG

# 10. Durum raporu
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  KURULUM TAMAMLANDI!                                       ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║                                                            ║"
echo "║  📦 Ollama API:    http://$(hostname -I | awk '{print $1}'):${OLLAMA_PORT}          ║"
echo "║  🌐 Open WebUI:    http://$(hostname -I | awk '{print $1}'):${WEBUI_PORT}           ║"
echo "║                                                            ║"
echo "║  📁 Veri Dizini:   ${DATA_DIR}                    ║"
echo "║  🤖 Modeller:      qwen2.5:0.5b, qwen2.5:1.5b, phi3:mini  ║"
echo "║                    344mehmet-assistant                     ║"
echo "║                                                            ║"
echo "╚═══════════════════════════════════════════════════════════╝"

# Modelleri listele
echo ""
echo "Yüklü modeller:"
docker exec ollama ollama list

echo ""
log_info "Test: ollama run 344mehmet-assistant"
