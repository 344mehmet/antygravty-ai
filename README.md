# 🤖 Antygravty AI - Otonom Gelir Sistemi

[![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Ollama](https://img.shields.io/badge/Ollama-Local%20LLM-orange.svg)](https://ollama.ai)

Kendi kendini eğiten, iş bulan, trading yapan ve gelir üreten **otonom AI sistemi**.

## 🌟 Özellikler

| Agent | Görev |
|-------|-------|
| **TradingAgent** | Binance/OKX spot trading, AI destekli sinyal |
| **CodingAgent** | Kod üretimi, MQL5 EA geliştirme |
| **JobHunterAgent** | Upwork/Fiverr iş arama, proposal |
| **SelfLearningAgent** | RAG güncelleme, fine-tuning |

## 📦 Kurulum

```bash
# Repo klonla
git clone https://github.com/344mehmet/antygravty-ai.git
cd antygravty-ai

# Bağımlılıkları yükle
pip install -r requirements.txt

# Ollama kurulumu
# Windows: https://ollama.ai/download
# Model indir
ollama pull qwen2.5:1.5b
ollama pull nomic-embed-text
```

## ⚙️ Yapılandırma

```bash
# .env dosyası oluştur
cp .env.example .env

# API anahtarlarını düzenle
# BINANCE_API_KEY, OKX_API_KEY, TELEGRAM_BOT_TOKEN
```

## 🚀 Kullanım

```bash
# Otonom sistemi başlat
python autonomous_agent_system.py

# Trading bot
python trading_bot.py

# RAG sistemi
python rag_system.py

# Özel AI asistan
ollama run 344mehmet-assistant
```

## 📁 Dosya Yapısı

```
antygravty-ai/
├── autonomous_agent_system.py  # Ana otonom sistem
├── trading_bot.py              # Binance/OKX trading
├── rag_system.py               # RAG vektör arama
├── llm_telegram_bot.py         # Telegram entegrasyonu
├── FINANCIAL_ORCHESTRATOR.py   # Orkestra Bot
├── Modelfile                   # Özel Ollama model
├── docker-compose-*.yml        # Docker yapılandırması
├── zimaos-*.sh                 # ZimaOS kurulum
└── beni oku/                   # Türkçe rehberler
```

## 🔧 Gereksinimler

- Python 3.10+
- Ollama
- (Opsiyonel) Binance/OKX API anahtarları
- (Opsiyonel) Telegram Bot Token

## 📄 Lisans

MIT License - Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 👤 Geliştirici

**344Mehmet**
- GitHub: [@344mehmet](https://github.com/344mehmet)

---

⭐ Beğendiyseniz yıldız verin!
