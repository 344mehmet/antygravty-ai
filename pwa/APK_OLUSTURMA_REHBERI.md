# LLM Ordusu - Android APK Oluşturma Rehberi

## 🎯 Seçenekler

### 1️⃣ PWA Kurulumu (En Kolay - Tavsiye)

PWA (Progressive Web App) doğrudan Chrome'dan kurulabilir:

1. **Chrome'da aç:** `http://192.168.1.46:8080/pwa/`
2. **Menü → Ana ekrana ekle**
3. **Uygulama gibi çalışır!**

✅ APK gerekmez
✅ Otomatik güncellenir
✅ Offline desteği

---

### 2️⃣ TWA ile APK (Android Studio)

**Trusted Web Activity** ile PWA'yı APK'ya çevir:

```bash
# Bubblewrap kurulumu
npm install -g @anthropic-ai/anthropic-sdk bubblewrap

# Proje oluştur
bubblewrap init --manifest https://your-server.com/pwa/manifest.json

# APK oluştur
bubblewrap build
```

**Gereksinimler:**
- Node.js
- Android SDK (Android Studio)
- Java JDK

---

### 3️⃣ Capacitor ile APK

```bash
cd pwa

# Capacitor kurulumu
npm init -y
npm install @capacitor/core @capacitor/cli @capacitor/android

# Başlat
npx cap init "LLM Ordusu" "com.llm.ordusu"

# Android platformu ekle
npx cap add android

# Build
npx cap copy android
npx cap open android
```

Android Studio'da:
- Build → Build Bundle(s) / APK(s) → Build APK(s)

---

### 4️⃣ Online APK Dönüştürücü

APK Generator sitelerini kullan:
- https://pwa2apk.com
- https://appmaker.xyz/pwa-to-apk
- https://gonative.io

URL gir → APK indir!

---

## 📱 PWA Dosyaları

```
pwa/
├── index.html      # Ana uygulama
├── manifest.json   # PWA yapılandırması
├── sw.js           # Service Worker
├── offline.html    # Çevrimdışı sayfa
└── icon-*.png      # Uygulama ikonları
```

---

## 🚀 Test Etme

```powershell
# Python server'ı başlat
python mobile_web_app.py

# veya sadece PWA klasörünü serve et
python -m http.server 8080 --directory pwa
```

Telefonda: `http://[IP]:8080/pwa/`

---

## 📍 Önerilen Yol

1. **Hemen kullanmak için:** PWA olarak Chrome'dan kur
2. **Play Store için:** Capacitor veya TWA ile APK oluştur
3. **Hızlı test için:** Online APK dönüştürücü

---

## 🔧 İkon Oluşturma

PNG ikonlarınızı oluşturun:
- `icon-192.png` (192x192 px)
- `icon-512.png` (512x512 px)

Online araçlar:
- https://realfavicongenerator.net
- https://maskable.app/editor
