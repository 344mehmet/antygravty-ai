"""
LangChain + Ollama + Telegram Bot Entegrasyonu
ZimaOS LLM Ordusu için
Antigravity AI - 29 Aralık 2025
"""

import os
import json
import requests
from typing import Optional

# ZimaOS Ollama API
OLLAMA_API = "http://192.168.1.43:11434"
DEFAULT_MODEL = "qwen2.5:0.5b"

class OllamaClient:
    """ZimaOS Ollama API istemcisi"""
    
    def __init__(self, base_url: str = OLLAMA_API):
        self.base_url = base_url
    
    def list_models(self) -> list:
        """Mevcut modelleri listele"""
        response = requests.get(f"{self.base_url}/api/tags")
        if response.ok:
            return response.json().get("models", [])
        return []
    
    def generate(self, prompt: str, model: str = DEFAULT_MODEL) -> str:
        """LLM'den yanıt al"""
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": False
        }
        response = requests.post(
            f"{self.base_url}/api/generate",
            json=payload,
            timeout=120
        )
        if response.ok:
            return response.json().get("response", "")
        return f"Hata: {response.status_code}"
    
    def pull_model(self, model_name: str) -> bool:
        """Model indir"""
        payload = {"name": model_name}
        response = requests.post(
            f"{self.base_url}/api/pull",
            json=payload,
            timeout=600
        )
        return response.ok


class TelegramBotHelper:
    """Telegram Bot için yardımcı fonksiyonlar"""
    
    def __init__(self, ollama_client: OllamaClient):
        self.ollama = ollama_client
    
    def generate_promotion_text(self, product: str, target: str) -> str:
        """Affiliate ürün için promosyon metni oluştur"""
        prompt = f"""
        Ürün: {product}
        Hedef Kitle: {target}
        
        Bu ürün için kısa ve etkili bir Türkçe promosyon metni yaz.
        Max 100 kelime, emoji kullan.
        """
        return self.ollama.generate(prompt)
    
    def generate_b2b_proposal(self, sector: str, pain_point: str, budget: str) -> str:
        """B2B satış teklifi oluştur"""
        prompt = f"""
        Sektör: {sector}
        Sorun: {pain_point}
        Bütçe: {budget}
        
        Bu müşteri için profesyonel bir AI otomasyon teklifi yaz.
        Max 150 kelime.
        """
        return self.ollama.generate(prompt)
    
    def analyze_market(self, crypto: str = "BTC") -> str:
        """Piyasa analizi yap"""
        prompt = f"""
        {crypto} için kısa bir teknik analiz özeti yaz.
        Trend, destek/direnç ve öneri dahil et.
        Max 50 kelime.
        """
        return self.ollama.generate(prompt)


def test_connection():
    """Bağlantı testi"""
    client = OllamaClient()
    
    print("🔍 Ollama API Test")
    print("-" * 40)
    
    # Model listesi
    models = client.list_models()
    if models:
        print(f"✅ Model sayısı: {len(models)}")
        for m in models:
            print(f"   - {m.get('name', 'N/A')}")
    else:
        print("⚠️ Henüz model yok")
    
    # Basit test
    if models:
        print("\n📝 LLM Testi...")
        response = client.generate("Merhaba, ben LLM Ordusu Başkanıyım.")
        print(f"Yanıt: {response[:200]}...")
    
    print("-" * 40)
    print("✅ Test tamamlandı")


if __name__ == "__main__":
    test_connection()
