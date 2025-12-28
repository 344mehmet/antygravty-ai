# 🤖 LLM Ordusu Merkezi Yönetim Sistemi

## 📋 İçindekiler
- [Genel Bakış](#genel-bakış)
- [Sistem Gereksinimleri](#sistem-gereksinimleri)
- [Kurulum](#kurulum)
- [Servisler](#servisler)
- [Kullanım](#kullanım)
- [LLM Modelleri](#llm-modelleri)
- [Ajan Sistemi](#ajan-sistemi)
- [Yedekleme](#yedekleme)
- [Sorun Giderme](#sorun-giderme)

---

## 🎯 Genel Bakış

Bu sistem, ZimaOS üzerinde çalışan kapsamlı bir yapay zeka ve LLM (Büyük Dil Modeli) yönetim merkezidir. AMD RX560/RX580 8GB GPU desteği ile yerel LLM çalıştırma, otomasyon ve çoklu ajan sistemleri sunar.

### Temel Özellikler
- 🎮 **AMD GPU Desteği**: ROCm ile GPU hızlandırmalı LLM çalıştırma
- 🐳 **Docker Tabanlı**: Kolay kurulum ve yönetim
- 🔒 **Güvenlik Odaklı**: Savunmacı ajan sistemleri
- 🌍 **Çoklu Dil**: Türkçe öncelikli, çoklu dil desteği
- 📊 **Tam İzleme**: Uptime Kuma ile sistem izleme
- 🔄 **Otomasyon**: n8n ile iş akışı otomasyonu

---

## 💻 Sistem Gereksinimleri

| Bileşen | Minimum | Önerilen |
|---------|---------|----------|
| **CPU** | 4 çekirdek | 8+ çekirdek |
| **RAM** | 8 GB | 32 GB |
| **GPU** | AMD RX560 8GB | AMD RX580 8GB |
| **Depolama** | 100 GB SSD | 500 GB+ NVMe |
| **Ağ** | 100 Mbps | Gigabit |

---

## 🚀 Kurulum

### 1. SSH Etkinleştirme (ZimaOS)
```
1. http://192.168.1.43 adresine gidin
2. Settings → Developer Mode → SSH Access → ON
3. Root şifresini belirleyin
```

### 2. Windows'tan SSH Bağlantısı
```powershell
ssh root@192.168.1.43
# veya
ssh zimaos
```

### 3. Kurulum Scriptini Çalıştırma
```bash
cd /DATA/Yonetim-Merkezi/scripts
chmod +x zimaos-setup.sh
./zimaos-setup.sh
```

### 4. Docker Compose Başlatma
```bash
cd /DATA/Yonetim-Merkezi/docker-compose
docker compose up -d
```

---

## 🔧 Servisler

| Servis | Port | Adres | Açıklama |
|--------|------|-------|----------|
| **Portainer** | 9443 | https://192.168.1.43:9443 | Docker Yönetimi |
| **Open WebUI** | 3000 | http://192.168.1.43:3000 | LLM Chat |
| **Ollama** | 11434 | http://192.168.1.43:11434 | LLM API |
| **n8n** | 5678 | http://192.168.1.43:5678 | Otomasyon |
| **Flowise** | 3002 | http://192.168.1.43:3002 | No-Code LLM |
| **Uptime Kuma** | 3001 | http://192.168.1.43:3001 | İzleme |
| **PostgreSQL** | 5432 | 192.168.1.43:5432 | Veritabanı |
| **MongoDB** | 27017 | 192.168.1.43:27017 | NoSQL DB |
| **ChromaDB** | 8000 | http://192.168.1.43:8000 | Vektör DB |
| **Nginx Proxy** | 81 | http://192.168.1.43:81 | Proxy Yönetimi |

### Varsayılan Giriş Bilgileri
- **Kullanıcı**: admin
- **Şifre**: Antigravity2025!

---

## 🤖 LLM Modelleri

### Kurulu Modeller
```bash
# Model listesi
docker exec ollama-amd ollama list

# Yeni model indirme
docker exec ollama-amd ollama pull <model_adi>
```

### Önerilen Modeller
| Model | Boyut | Kullanım |
|-------|-------|----------|
| llama2:7b | 4GB | Genel amaçlı |
| mistral:7b | 4GB | Hızlı yanıt |
| codellama:7b | 4GB | Kod yazma |
| deepseek-r1:14b | 8GB | Muhakeme |
| qwen2.5:14b | 8GB | Çok dilli |

### API Kullanımı
```python
import requests

response = requests.post(
    "http://192.168.1.43:11434/api/generate",
    json={
        "model": "llama2:7b",
        "prompt": "Merhaba, nasılsın?",
        "stream": False
    }
)
print(response.json()["response"])
```

---

## 🛡️ Ajan Sistemi

### Ajan Türleri

#### 1. Savunma Ajanları (`/DATA/LLM-Ordusu/agents/defensive`)
- Tehdit tespiti ve analizi
- Güvenlik taraması
- Anomali izleme
- Log analizi

#### 2. Yönetim Ajanları (`/DATA/LLM-Ordusu/agents/management`)
- Kaynak izleme
- Otomatik yedekleme
- Sistem güncellemesi
- Performans optimizasyonu

#### 3. Otomasyon Ajanları (`/DATA/LLM-Ordusu/agents/automation`)
- Veri işleme
- Raporlama
- Entegrasyon görevleri
- Zamanlı görevler

---

## 💾 Yedekleme

### Windows'tan Yedekleme
```powershell
# Yedekleme scripti
.\sync_zimaos.ps1 -Backup

# Senkronizasyon
.\sync_zimaos.ps1 -Sync

# Durum kontrolü
.\sync_zimaos.ps1 -Status
```

### Otomatik Yedekleme
- Saat: Her gün 03:00
- Konum: `Z:\Yonetim-Merkezi\backups`
- Saklama: 30 gün

---

## 🔧 Sorun Giderme

### Servis Durumu Kontrolü
```bash
docker ps
docker logs <container_adi>
```

### GPU Kontrolü
```bash
# AMD GPU durumu
rocm-smi

# Docker GPU erişimi
docker exec ollama-amd rocm-smi
```

### Ağ Sorunları
```powershell
# Windows'tan
Test-NetConnection -ComputerName 192.168.1.43 -Port 22
ping 192.168.1.43
```

### Servisleri Yeniden Başlatma
```bash
cd /DATA/Yonetim-Merkezi/docker-compose
docker compose restart
```

---

## 📞 Hızlı Erişim

### ZeroTier (VPN)
- Ağ ID: 3ab3c8769bdea09b
- ZimaOS IP: 10.147.11.1
- Windows IP: 10.147.11.32

### SSH Bağlantısı
```
ssh zimaos           # Yerel ağ
ssh zimaos-zerotier  # VPN üzerinden
```

---

## 📝 Lisans ve Telif

Bu sistem Antigravity projesi kapsamında geliştirilmiştir.
Tüm hakları saklıdır. © 2025

---

**Son Güncelleme**: 28 Aralık 2025
