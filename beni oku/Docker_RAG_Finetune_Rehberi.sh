# Docker RAG ve LLM Fine-tuning Kullanım Rehberi
# 344Mehmet LLM Ordusu
# =====================================================

# ⚙️ GEREKLİ YAZILIMLAR
# ---------------------
# - Docker Desktop (Windows/Mac) veya Docker Engine (Linux)
# - Docker Compose v2+
# - (Fine-tuning için) NVIDIA GPU + NVIDIA Container Toolkit

# =====================================================
# 📚 RAG SİSTEMİ KURULUMU
# =====================================================

# 1. RAG sistemini başlat (Qdrant + RAG API)
docker-compose -f docker-compose-rag.yml up -d

# 2. Durumu kontrol et
docker-compose -f docker-compose-rag.yml ps

# 3. Logları izle
docker-compose -f docker-compose-rag.yml logs -f rag-api

# 4. RAG API'yi test et
# Health check:
curl http://localhost:8000/health

# Doküman ekle:
curl -X POST http://localhost:8000/ingest \
  -H "Content-Type: application/json" \
  -d '{"text": "ZimaOS NAS IP adresi 192.168.1.43", "metadata": {"source": "config"}}'

# Soru sor (RAG):
curl -X POST http://localhost:8000/query \
  -H "Content-Type: application/json" \
  -d '{"query": "ZimaOS IP adresi nedir?", "top_k": 3}'

# 5. Durdur
docker-compose -f docker-compose-rag.yml down

# =====================================================
# 🎯 FINE-TUNING KURULUMU
# =====================================================

# ÖNEMLİ: GPU kullanımı için NVIDIA Container Toolkit gerekli
# Kurulum: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html

# 1. Output klasörünü oluştur
mkdir -p finetune_output

# 2. GPU ile eğitim başlat
docker-compose -f docker-compose-finetune.yml up finetune

# 3. VEYA CPU ile eğitim (GPU yoksa, daha yavaş)
docker-compose -f docker-compose-finetune.yml --profile cpu-only up finetune-cpu

# 4. Eğitim loglarını izle
docker logs -f llm-finetune

# 5. Eğitilmiş modeli kontrol et
ls -la finetune_output/

# =====================================================
# 🚀 EĞİTİLMİŞ MODELİ OLLAMA'YA YÜKLEME
# =====================================================

# 1. GGUF dosyasını bul
ls finetune_output/gguf/

# 2. Modelfile oluştur
cat > Modelfile.trained << 'EOF'
FROM ./finetune_output/gguf/unsloth.Q4_K_M.gguf

PARAMETER temperature 0.7
PARAMETER top_p 0.9

SYSTEM """
Sen 344Mehmet'in özel eğitilmiş AI asistanısın.
"""
EOF

# 3. Ollama'ya yükle
ollama create 344mehmet-finetuned -f Modelfile.trained

# 4. Test et
ollama run 344mehmet-finetuned "Merhaba, kimsin?"

# =====================================================
# 📊 API ENDPOİNTLERİ
# =====================================================

# RAG API (Port 8000):
# - GET  /health         - Sağlık kontrolü
# - GET  /collections    - Koleksiyonları listele
# - GET  /stats          - İstatistikler
# - POST /ingest         - Tek doküman ekle
# - POST /ingest/batch   - Toplu doküman ekle
# - POST /query          - RAG sorgusu yap
# - DELETE /collection/{name} - Koleksiyon sil

# Qdrant (Port 6333):
# - Dashboard: http://localhost:6333/dashboard

# =====================================================
# 🔧 SORUN GİDERME
# =====================================================

# Konteyner durumunu kontrol et
docker ps -a

# Logları görüntüle
docker logs qdrant
docker logs rag-api
docker logs llm-finetune

# Konteynerı yeniden başlat
docker restart rag-api

# Tüm sistemi sıfırla
docker-compose -f docker-compose-rag.yml down -v
docker-compose -f docker-compose-rag.yml up -d --build

# =====================================================
# 📌 ZIMAOS NAS ÜZERİNDE ÇALIŞTIRMA
# =====================================================

# 1. Dosyaları ZimaOS'a kopyala
scp -r docker-compose-rag.yml rag_docker root@192.168.1.43:/root/

# 2. SSH ile bağlan
ssh root@192.168.1.43

# 3. RAG sistemini başlat
cd /root
docker-compose -f docker-compose-rag.yml up -d

# 4. API'ye ağ üzerinden eriş
# http://192.168.1.43:8000 (RAG API)
# http://192.168.1.43:6333 (Qdrant)
