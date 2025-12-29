"""
BINANCE & OKX TRADING BOT
Gerçek API Entegrasyonu - Spot Trading
344Mehmet - 29 Aralık 2025

⚠️ UYARI: Bu bot gerçek para ile işlem yapabilir!
Önce TESTNET modunda test edin.
"""

import os
import json
import time
import hmac
import hashlib
import requests
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass

# ============================================
# YAPILANDIRMA
# ============================================

# Binance API (TR veya Global)
BINANCE_API_KEY = os.getenv("BINANCE_API_KEY", "")
BINANCE_SECRET = os.getenv("BINANCE_SECRET", "")
BINANCE_BASE_URL = "https://api.binance.com"  # TR: trbinance.com

# OKX API
OKX_API_KEY = os.getenv("OKX_API_KEY", "")
OKX_SECRET = os.getenv("OKX_SECRET", "")
OKX_PASSPHRASE = os.getenv("OKX_PASSPHRASE", "")
OKX_BASE_URL = "https://www.okx.com"

# Ollama
OLLAMA_API = "http://localhost:11434"

# ============================================
# VERİ YAPILARI
# ============================================

@dataclass
class MarketData:
    symbol: str
    price: float
    change_24h: float
    volume: float
    high_24h: float
    low_24h: float
    timestamp: datetime

@dataclass
class Order:
    order_id: str
    symbol: str
    side: str
    type: str
    quantity: float
    price: float
    status: str
    timestamp: datetime

# ============================================
# BINANCE CLIENT
# ============================================

class BinanceClient:
    """Binance Spot Trading API"""
    
    def __init__(self, api_key: str = BINANCE_API_KEY, secret: str = BINANCE_SECRET, testnet: bool = True):
        self.api_key = api_key
        self.secret = secret
        self.base_url = "https://testnet.binance.vision" if testnet else BINANCE_BASE_URL
        self.testnet = testnet
    
    def _sign(self, params: Dict) -> str:
        """HMAC SHA256 imza oluştur"""
        query_string = "&".join([f"{k}={v}" for k, v in params.items()])
        signature = hmac.new(
            self.secret.encode('utf-8'),
            query_string.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
        return signature
    
    def _request(self, method: str, endpoint: str, params: Dict = None, signed: bool = False) -> Dict:
        """API isteği gönder"""
        url = f"{self.base_url}{endpoint}"
        headers = {"X-MBX-APIKEY": self.api_key}
        
        if params is None:
            params = {}
        
        if signed:
            params["timestamp"] = int(time.time() * 1000)
            params["signature"] = self._sign(params)
        
        try:
            if method == "GET":
                response = requests.get(url, params=params, headers=headers, timeout=30)
            elif method == "POST":
                response = requests.post(url, params=params, headers=headers, timeout=30)
            elif method == "DELETE":
                response = requests.delete(url, params=params, headers=headers, timeout=30)
            
            return response.json()
        except Exception as e:
            return {"error": str(e)}
    
    def get_ticker(self, symbol: str = "BTCUSDT") -> MarketData:
        """Fiyat bilgisi al"""
        data = self._request("GET", "/api/v3/ticker/24hr", {"symbol": symbol})
        
        return MarketData(
            symbol=symbol,
            price=float(data.get("lastPrice", 0)),
            change_24h=float(data.get("priceChangePercent", 0)),
            volume=float(data.get("volume", 0)),
            high_24h=float(data.get("highPrice", 0)),
            low_24h=float(data.get("lowPrice", 0)),
            timestamp=datetime.now()
        )
    
    def get_balance(self) -> Dict:
        """Hesap bakiyesi"""
        data = self._request("GET", "/api/v3/account", signed=True)
        
        balances = {}
        for asset in data.get("balances", []):
            free = float(asset.get("free", 0))
            if free > 0:
                balances[asset["asset"]] = free
        
        return balances
    
    def place_order(self, symbol: str, side: str, quantity: float, 
                    order_type: str = "MARKET", price: float = None) -> Order:
        """Emir ver"""
        params = {
            "symbol": symbol,
            "side": side.upper(),
            "type": order_type.upper(),
            "quantity": quantity
        }
        
        if order_type.upper() == "LIMIT" and price:
            params["price"] = price
            params["timeInForce"] = "GTC"
        
        data = self._request("POST", "/api/v3/order", params, signed=True)
        
        return Order(
            order_id=str(data.get("orderId", "")),
            symbol=symbol,
            side=side,
            type=order_type,
            quantity=quantity,
            price=float(data.get("price", price or 0)),
            status=data.get("status", "UNKNOWN"),
            timestamp=datetime.now()
        )
    
    def get_orders(self, symbol: str) -> List[Order]:
        """Açık emirleri listele"""
        data = self._request("GET", "/api/v3/openOrders", {"symbol": symbol}, signed=True)
        
        orders = []
        for o in data:
            orders.append(Order(
                order_id=str(o.get("orderId")),
                symbol=o.get("symbol"),
                side=o.get("side"),
                type=o.get("type"),
                quantity=float(o.get("origQty", 0)),
                price=float(o.get("price", 0)),
                status=o.get("status"),
                timestamp=datetime.now()
            ))
        
        return orders
    
    def cancel_order(self, symbol: str, order_id: str) -> Dict:
        """Emir iptal et"""
        return self._request("DELETE", "/api/v3/order", 
                           {"symbol": symbol, "orderId": order_id}, signed=True)

# ============================================
# OKX CLIENT
# ============================================

class OKXClient:
    """OKX Spot Trading API"""
    
    def __init__(self, api_key: str = OKX_API_KEY, secret: str = OKX_SECRET,
                 passphrase: str = OKX_PASSPHRASE, demo: bool = True):
        self.api_key = api_key
        self.secret = secret
        self.passphrase = passphrase
        self.base_url = "https://www.okx.com"
        self.demo = demo
    
    def _get_timestamp(self) -> str:
        """ISO 8601 timestamp"""
        return datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'
    
    def _sign(self, timestamp: str, method: str, path: str, body: str = "") -> str:
        """HMAC SHA256 Base64 imza"""
        message = timestamp + method + path + body
        signature = hmac.new(
            self.secret.encode('utf-8'),
            message.encode('utf-8'),
            hashlib.sha256
        )
        import base64
        return base64.b64encode(signature.digest()).decode()
    
    def _request(self, method: str, path: str, params: Dict = None) -> Dict:
        """API isteği"""
        timestamp = self._get_timestamp()
        
        body = ""
        if params and method == "POST":
            body = json.dumps(params)
        
        signature = self._sign(timestamp, method, path, body)
        
        headers = {
            "OK-ACCESS-KEY": self.api_key,
            "OK-ACCESS-SIGN": signature,
            "OK-ACCESS-TIMESTAMP": timestamp,
            "OK-ACCESS-PASSPHRASE": self.passphrase,
            "Content-Type": "application/json"
        }
        
        if self.demo:
            headers["x-simulated-trading"] = "1"
        
        url = f"{self.base_url}{path}"
        
        try:
            if method == "GET":
                response = requests.get(url, headers=headers, timeout=30)
            elif method == "POST":
                response = requests.post(url, headers=headers, data=body, timeout=30)
            
            return response.json()
        except Exception as e:
            return {"error": str(e)}
    
    def get_ticker(self, symbol: str = "BTC-USDT") -> MarketData:
        """Fiyat bilgisi"""
        data = self._request("GET", f"/api/v5/market/ticker?instId={symbol}")
        
        ticker = data.get("data", [{}])[0]
        
        return MarketData(
            symbol=symbol,
            price=float(ticker.get("last", 0)),
            change_24h=float(ticker.get("changePerc24h", 0)) if ticker.get("changePerc24h") else 0,
            volume=float(ticker.get("vol24h", 0)),
            high_24h=float(ticker.get("high24h", 0)),
            low_24h=float(ticker.get("low24h", 0)),
            timestamp=datetime.now()
        )
    
    def get_balance(self) -> Dict:
        """Bakiye"""
        data = self._request("GET", "/api/v5/account/balance")
        
        balances = {}
        for detail in data.get("data", [{}])[0].get("details", []):
            avail = float(detail.get("availBal", 0))
            if avail > 0:
                balances[detail["ccy"]] = avail
        
        return balances
    
    def place_order(self, symbol: str, side: str, quantity: float,
                    order_type: str = "market", price: float = None) -> Order:
        """Emir ver"""
        params = {
            "instId": symbol,
            "tdMode": "cash",  # Spot için
            "side": side.lower(),
            "ordType": order_type.lower(),
            "sz": str(quantity)
        }
        
        if order_type.lower() == "limit" and price:
            params["px"] = str(price)
        
        data = self._request("POST", "/api/v5/trade/order", params)
        
        order_data = data.get("data", [{}])[0]
        
        return Order(
            order_id=order_data.get("ordId", ""),
            symbol=symbol,
            side=side,
            type=order_type,
            quantity=quantity,
            price=price or 0,
            status=order_data.get("sCode", "UNKNOWN"),
            timestamp=datetime.now()
        )

# ============================================
# AI TRADİNG STRATEJİSİ
# ============================================

class AITradingStrategy:
    """LLM destekli trading stratejisi"""
    
    def __init__(self, binance: BinanceClient, okx: OKXClient):
        self.binance = binance
        self.okx = okx
        self.positions = []
        self.history = []
    
    def _get_llm_signal(self, market_data: MarketData) -> str:
        """LLM'den trading sinyali al"""
        try:
            data = json.dumps({
                "model": "344mehmet-assistant",
                "prompt": f"""Kripto piyasa analizi:
Symbol: {market_data.symbol}
Fiyat: ${market_data.price}
24h Değişim: %{market_data.change_24h}
24h Volume: {market_data.volume}
24h High: ${market_data.high_24h}
24h Low: ${market_data.low_24h}

Bu verilerle trading sinyali ver. Sadece şu formatla cevap ver:
SIGNAL: BUY veya SELL veya HOLD
REASON: Kısa açıklama""",
                "stream": False
            }).encode('utf-8')
            
            req = requests.post(
                f"{OLLAMA_API}/api/generate",
                data=data,
                headers={'Content-Type': 'application/json'},
                timeout=60
            )
            
            if req.ok:
                response = req.json().get("response", "HOLD")
                return response
            return "HOLD"
        except:
            return "HOLD"
    
    def analyze_and_trade(self, symbol: str = "BTCUSDT", exchange: str = "binance", 
                          trade_amount: float = 10.0):
        """Analiz yap ve trade öner"""
        
        # Piyasa verisi al
        if exchange == "binance":
            market = self.binance.get_ticker(symbol)
        else:
            market = self.okx.get_ticker(symbol.replace("USDT", "-USDT"))
        
        print(f"\n📊 {market.symbol} @ ${market.price:.2f} ({market.change_24h:+.2f}%)")
        
        # LLM analizi
        signal = self._get_llm_signal(market)
        print(f"🤖 AI Sinyali:\n{signal[:200]}")
        
        # Sinyal parse
        if "BUY" in signal.upper():
            print(f"✅ AL sinyali - {trade_amount} USDT")
            # self.binance.place_order(symbol, "BUY", trade_amount / market.price)
        elif "SELL" in signal.upper():
            print(f"🔴 SAT sinyali")
            # self.binance.place_order(symbol, "SELL", trade_amount / market.price)
        else:
            print("⏸️ BEKLE sinyali")
        
        self.history.append({
            "timestamp": datetime.now().isoformat(),
            "symbol": symbol,
            "price": market.price,
            "signal": signal[:100]
        })
        
        return {"market": market, "signal": signal}

# ============================================
# ANA FONKSİYON
# ============================================

def main():
    print("""
╔═══════════════════════════════════════════════════════════╗
║  BINANCE & OKX TRADING BOT                                ║
║  AI Destekli Spot Trading                                 ║
╚═══════════════════════════════════════════════════════════╝
    """)
    
    # Client'ları oluştur (TESTNET modunda)
    binance = BinanceClient(testnet=True)
    okx = OKXClient(demo=True)
    
    # Strategy oluştur
    strategy = AITradingStrategy(binance, okx)
    
    # Test: Binance ticker
    print("\n[1] Binance Fiyat Testi")
    try:
        btc = binance.get_ticker("BTCUSDT")
        print(f"   BTC/USDT: ${btc.price:.2f}")
    except Exception as e:
        print(f"   Hata: {e}")
    
    # Test: OKX ticker
    print("\n[2] OKX Fiyat Testi")
    try:
        btc_okx = okx.get_ticker("BTC-USDT")
        print(f"   BTC-USDT: ${btc_okx.price:.2f}")
    except Exception as e:
        print(f"   Hata: {e}")
    
    # Test: AI Trading
    print("\n[3] AI Trading Analizi")
    result = strategy.analyze_and_trade("BTCUSDT")
    
    print("\n" + "=" * 50)
    print("  BOT HAZIR!")
    print("=" * 50)
    print("""
⚠️ UYARI:
1. API anahtarlarını .env dosyasına koyun
2. Önce testnet'te test edin
3. Risk yönetimi uygulayın

Sürekli trading için:
  while True:
      strategy.analyze_and_trade("BTCUSDT")
      time.sleep(3600)  # 1 saat bekle
""")

if __name__ == "__main__":
    main()
