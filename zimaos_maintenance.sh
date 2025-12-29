#!/bin/bash
# =====================================================
# ZimaOS Sistem Bakım ve Stabilite Script'i
# Açılma sorunlarını önlemek için kapsamlı bakım
# =====================================================

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ZimaOS Sistem Bakım ve Stabilite Script'i        ║${NC}"
echo -e "${BLUE}║   Açılma Sorunlarını Önleme                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# =====================================================
# 1. DISK ALANI KONTROLÜ
# =====================================================
echo -e "${YELLOW}[1/8] Disk Alanı Kontrolü...${NC}"

# ZimaOS-HD doluluk kontrolü (kritik)
ROOT_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$ROOT_USAGE" -gt 85 ]; then
    echo -e "${RED}⚠️  ROOT disk %${ROOT_USAGE} dolu - tehlikeli seviye!${NC}"
    echo -e "${YELLOW}   Temizlik yapılıyor...${NC}"
    
    # Log dosyalarını temizle
    journalctl --vacuum-time=3d
    journalctl --vacuum-size=100M
    
    # Eski Docker imajlarını temizle
    docker image prune -af --filter "until=168h"
    
    # Tmp dosyalarını temizle
    find /tmp -type f -atime +3 -delete 2>/dev/null
    
    echo -e "${GREEN}   ✓ Temizlik tamamlandı${NC}"
else
    echo -e "${GREEN}   ✓ ROOT disk %${ROOT_USAGE} - normal${NC}"
fi

DATA_USAGE=$(df -h /DATA 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
if [ -n "$DATA_USAGE" ]; then
    if [ "$DATA_USAGE" -gt 90 ]; then
        echo -e "${RED}   ⚠️  DATA disk %${DATA_USAGE} dolu!${NC}"
    else
        echo -e "${GREEN}   ✓ DATA disk %${DATA_USAGE} - normal${NC}"
    fi
fi

# =====================================================
# 2. DOCKER SERVİS KONTROLÜ
# =====================================================
echo -e "${YELLOW}[2/8] Docker Servis Kontrolü...${NC}"

if systemctl is-active --quiet docker; then
    echo -e "${GREEN}   ✓ Docker servisi çalışıyor${NC}"
else
    echo -e "${RED}   ⚠️  Docker servisi durmuş - yeniden başlatılıyor${NC}"
    systemctl restart docker docker.socket
    sleep 5
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}   ✓ Docker yeniden başlatıldı${NC}"
    else
        echo -e "${RED}   ✗ Docker başlatılamadı!${NC}"
    fi
fi

# =====================================================
# 3. DOCKER KAYNAK TEMİZLİĞİ
# =====================================================
echo -e "${YELLOW}[3/8] Docker Kaynak Temizliği...${NC}"

# Durmuş konteynerları temizle
STOPPED=$(docker ps -aq -f status=exited | wc -l)
if [ "$STOPPED" -gt 0 ]; then
    echo -e "${YELLOW}   $STOPPED durmuş konteyner temizleniyor...${NC}"
    docker container prune -f
fi

# Kullanılmayan volumeleri temizle (dikkatli)
UNUSED_VOLUMES=$(docker volume ls -q -f dangling=true | wc -l)
if [ "$UNUSED_VOLUMES" -gt 0 ]; then
    echo -e "${YELLOW}   $UNUSED_VOLUMES kullanılmayan volume temizleniyor...${NC}"
    docker volume prune -f
fi

# Kullanılmayan ağları temizle
docker network prune -f 2>/dev/null

echo -e "${GREEN}   ✓ Docker temizliği tamamlandı${NC}"

# =====================================================
# 4. NETWORK AYARLARI OPTİMİZASYONU
# =====================================================
echo -e "${YELLOW}[4/8] Network Ayarları Kontrolü...${NC}"

# NetworkManager durumu
if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    echo -e "${GREEN}   ✓ NetworkManager çalışıyor${NC}"
fi

# Ağ arayüzü durumu
ACTIVE_IFACE=$(ip route | grep default | awk '{print $5}')
if [ -n "$ACTIVE_IFACE" ]; then
    IP_ADDR=$(ip -4 addr show $ACTIVE_IFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    echo -e "${GREEN}   ✓ Aktif arayüz: $ACTIVE_IFACE ($IP_ADDR)${NC}"
    
    # Energy Efficient Ethernet devre dışı bırak (ağ sorunları için)
    ethtool --set-eee $ACTIVE_IFACE eee off 2>/dev/null && \
        echo -e "${GREEN}   ✓ EEE devre dışı bırakıldı (ağ stabilitesi için)${NC}"
else
    echo -e "${RED}   ⚠️  Aktif ağ arayüzü bulunamadı!${NC}"
fi

# =====================================================
# 5. SWAP VE BELLEK OPTİMİZASYONU
# =====================================================
echo -e "${YELLOW}[5/8] Bellek Optimizasyonu...${NC}"

# Mevcut bellek durumu
MEM_FREE=$(free -m | awk 'NR==2 {print $4}')
MEM_TOTAL=$(free -m | awk 'NR==2 {print $2}')
MEM_PERCENT=$((100 - (MEM_FREE * 100 / MEM_TOTAL)))

echo -e "${GREEN}   ✓ Bellek kullanımı: %${MEM_PERCENT} (${MEM_FREE}MB boş / ${MEM_TOTAL}MB toplam)${NC}"

# Buffer/cache temizle (kritik durumlarda)
if [ "$MEM_PERCENT" -gt 90 ]; then
    echo -e "${YELLOW}   Bellek önbellekleri temizleniyor...${NC}"
    sync
    echo 3 > /proc/sys/vm/drop_caches
    echo -e "${GREEN}   ✓ Önbellek temizlendi${NC}"
fi

# =====================================================
# 6. SİSTEM SERVİSLERİ KONTROLÜ
# =====================================================
echo -e "${YELLOW}[6/8] Kritik Servisler Kontrolü...${NC}"

CRITICAL_SERVICES=("docker" "containerd" "casaos-gateway" "casaos-local-storage")

for service in "${CRITICAL_SERVICES[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${GREEN}   ✓ $service çalışıyor${NC}"
    else
        echo -e "${YELLOW}   ⚠️  $service durmuş - başlatılıyor...${NC}"
        systemctl start "$service" 2>/dev/null
    fi
done

# =====================================================
# 7. BOOT PARTITION KONTROLÜ
# =====================================================
echo -e "${YELLOW}[7/8] Boot Partition Kontrolü...${NC}"

# Mevcut boot slot kontrolü
CURRENT_SLOT=$(rauc status 2>/dev/null | grep "activated" | head -1 || echo "Bilinmiyor")
echo -e "${GREEN}   ✓ Boot durumu: $CURRENT_SLOT${NC}"

# Boot partition doluluk kontrolü
BOOT_USAGE=$(df -h /boot 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
if [ -n "$BOOT_USAGE" ]; then
    if [ "$BOOT_USAGE" -gt 80 ]; then
        echo -e "${RED}   ⚠️  Boot partition %${BOOT_USAGE} dolu!${NC}"
    else
        echo -e "${GREEN}   ✓ Boot partition %${BOOT_USAGE} - normal${NC}"
    fi
fi

# =====================================================
# 8. KONTEYNER SAĞLIK KONTROLÜ
# =====================================================
echo -e "${YELLOW}[8/8] Konteyner Sağlık Kontrolü...${NC}"

# Çalışan konteynerları listele
RUNNING=$(docker ps -q | wc -l)
TOTAL=$(docker ps -aq | wc -l)
echo -e "${GREEN}   ✓ Konteynerlar: $RUNNING çalışıyor / $TOTAL toplam${NC}"

# Unhealthy konteynerları kontrol et
UNHEALTHY=$(docker ps --filter "health=unhealthy" -q | wc -l)
if [ "$UNHEALTHY" -gt 0 ]; then
    echo -e "${RED}   ⚠️  $UNHEALTHY sağlıksız konteyner var:${NC}"
    docker ps --filter "health=unhealthy" --format "   - {{.Names}} ({{.Status}})"
    
    echo -e "${YELLOW}   Sağlıksız konteynerler yeniden başlatılıyor...${NC}"
    docker ps --filter "health=unhealthy" -q | xargs -r docker restart
fi

# =====================================================
# ÖZET RAPOR
# =====================================================
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║               BAKIM ÖZET RAPORU                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo -e "   Tarih: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "   Sistem: $(uname -r)"
echo -e "   Uptime: $(uptime -p)"
echo -e "   Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
echo -e "   ROOT Disk: %${ROOT_USAGE}"
echo -e "   Bellek: %${MEM_PERCENT}"
echo -e "   Konteynerlar: ${RUNNING}/${TOTAL}"
echo ""
echo -e "${GREEN}✅ Bakım tamamlandı! Sistem stabil durumda.${NC}"
echo ""

# =====================================================
# CRON JOB KURULUMU (Haftalık bakım)
# =====================================================
CRON_CMD="0 3 * * 0 /root/zimaos_maintenance.sh >> /var/log/zimaos_maintenance.log 2>&1"

if ! crontab -l 2>/dev/null | grep -q "zimaos_maintenance.sh"; then
    echo -e "${YELLOW}Haftalık otomatik bakım ayarlanıyor...${NC}"
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
    echo -e "${GREEN}✓ Her Pazar saat 03:00'te otomatik bakım yapılacak${NC}"
fi
