"""
OTONOM AI GELİR SİSTEMİ
Kendi kendini eğiten, iş bulan, trading yapan AI
344Mehmet - 29 Aralık 2025
"""

import os
import json
import time
import hashlib
import threading
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from enum import Enum

# ============================================
# YAPILANDIRMA
# ============================================

OLLAMA_API = "http://localhost:11434"
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "")

# Borsa API Anahtarları (ENV'den al)
BINANCE_API_KEY = os.getenv("BINANCE_API_KEY", "")
BINANCE_SECRET = os.getenv("BINANCE_SECRET", "")
OKX_API_KEY = os.getenv("OKX_API_KEY", "")
OKX_SECRET = os.getenv("OKX_SECRET", "")
OKX_PASSPHRASE = os.getenv("OKX_PASSPHRASE", "")

# ============================================
# VERİ YAPILARI
# ============================================

class AgentStatus(Enum):
    IDLE = "idle"
    WORKING = "working"
    LEARNING = "learning"
    TRADING = "trading"
    ERROR = "error"

@dataclass
class Trade:
    symbol: str
    side: str  # BUY/SELL
    amount: float
    price: float
    timestamp: datetime
    profit: float = 0.0
    exchange: str = "binance"

@dataclass
class Job:
    title: str
    description: str
    budget: float
    platform: str  # upwork/fiverr
    url: str
    status: str = "pending"
    proposal_sent: bool = False

@dataclass
class AgentState:
    name: str
    status: AgentStatus = AgentStatus.IDLE
    last_action: str = ""
    total_earnings: float = 0.0
    tasks_completed: int = 0
    errors: int = 0

# ============================================
# TEMEL AI İSTEMCİ
# ============================================

class OllamaClient:
    """Ollama API istemcisi"""
    
    def __init__(self, base_url: str = OLLAMA_API, model: str = "344mehmet-assistant"):
        self.base_url = base_url
        self.model = model
    
    def generate(self, prompt: str, system: str = None) -> str:
        """LLM'den yanıt al"""
        try:
            import urllib.request
            
            messages = []
            if system:
                messages.append({"role": "system", "content": system})
            messages.append({"role": "user", "content": prompt})
            
            data = json.dumps({
                "model": self.model,
                "prompt": prompt,
                "stream": False
            }).encode('utf-8')
            
            req = urllib.request.Request(
                f"{self.base_url}/api/generate",
                data=data,
                headers={'Content-Type': 'application/json'}
            )
            
            with urllib.request.urlopen(req, timeout=120) as response:
                result = json.loads(response.read().decode())
                return result.get("response", "")
        except Exception as e:
            return f"Hata: {e}"
    
    def analyze(self, data: Dict) -> Dict:
        """Veri analizi yap"""
        prompt = f"Aşağıdaki veriyi analiz et ve JSON formatında sonuç ver:\n{json.dumps(data, ensure_ascii=False)}"
        response = self.generate(prompt)
        try:
            return json.loads(response)
        except:
            return {"analysis": response}

# ============================================
# TRADING AGENT
# ============================================

class TradingAgent:
    """Binance ve OKX için otonom trading agent"""
    
    def __init__(self, llm_client: OllamaClient):
        self.llm = llm_client
        self.state = AgentState(name="TradingAgent")
        self.trades: List[Trade] = []
        self.balance = {"USDT": 0.0}
        self.risk_limit = 0.02  # %2 risk limiti
        
    def analyze_market(self, symbol: str = "BTC/USDT") -> Dict:
        """Piyasa analizi yap"""
        self.state.status = AgentStatus.WORKING
        
        # Gerçek implementasyonda API'den veri çekilir
        market_data = {
            "symbol": symbol,
            "price": 0.0,
            "change_24h": 0.0,
            "volume": 0.0,
            "rsi": 50,
            "ema_9": 0.0,
            "ema_21": 0.0
        }
        
        analysis = self.llm.generate(
            f"Şu piyasa verilerini analiz et ve trading sinyali ver (BUY/SELL/HOLD): {json.dumps(market_data)}",
            system="Sen bir kripto trading uzmanısın. Kısa ve net sinyal ver."
        )
        
        self.state.last_action = f"Piyasa analizi: {symbol}"
        return {"signal": analysis, "data": market_data}
    
    def execute_trade(self, symbol: str, side: str, amount: float, exchange: str = "binance") -> Optional[Trade]:
        """Trade işlemi yap"""
        self.state.status = AgentStatus.TRADING
        
        # Risk kontrolü
        if amount > self.balance.get("USDT", 0) * self.risk_limit:
            print(f"⚠️ Risk limiti aşıldı: {amount}")
            return None
        
        trade = Trade(
            symbol=symbol,
            side=side,
            amount=amount,
            price=0.0,  # API'den alınır
            timestamp=datetime.now(),
            exchange=exchange
        )
        
        self.trades.append(trade)
        self.state.tasks_completed += 1
        self.state.last_action = f"Trade: {side} {amount} {symbol}"
        
        print(f"✅ Trade: {side} {amount} {symbol} @ {exchange}")
        return trade
    
    def get_portfolio(self) -> Dict:
        """Portföy durumu"""
        total_profit = sum(t.profit for t in self.trades)
        return {
            "balance": self.balance,
            "total_trades": len(self.trades),
            "total_profit": total_profit,
            "agent_status": self.state.status.value
        }
    
    def run_strategy(self, strategy: str = "grid"):
        """Trading stratejisi çalıştır"""
        if strategy == "grid":
            self._grid_trading()
        elif strategy == "dca":
            self._dca_trading()
        elif strategy == "scalping":
            self._scalping()
    
    def _grid_trading(self):
        """Grid trading stratejisi"""
        # Implementasyon
        pass
    
    def _dca_trading(self):
        """DCA stratejisi"""
        pass
    
    def _scalping(self):
        """Scalping stratejisi"""
        pass

# ============================================
# CODING AGENT
# ============================================

class CodingAgent:
    """Kod üretimi ve proje geliştirme agent"""
    
    def __init__(self, llm_client: OllamaClient):
        self.llm = llm_client
        self.state = AgentState(name="CodingAgent")
        self.projects: List[Dict] = []
    
    def design_architecture(self, requirements: str) -> str:
        """Proje mimarisi tasarla"""
        self.state.status = AgentStatus.WORKING
        
        prompt = f"""Aşağıdaki gereksinimler için yazılım mimarisi tasarla:

{requirements}

Şunları içer:
1. Dosya yapısı
2. Sınıf diyagramı
3. Kullanılacak teknolojiler
4. API tasarımı"""
        
        architecture = self.llm.generate(prompt)
        self.state.last_action = "Mimari tasarım oluşturuldu"
        return architecture
    
    def generate_code(self, spec: str, language: str = "python") -> str:
        """Kod üret"""
        self.state.status = AgentStatus.WORKING
        
        prompt = f"Şu spesifikasyona göre {language} kodu yaz:\n{spec}"
        code = self.llm.generate(prompt)
        
        self.state.tasks_completed += 1
        self.state.last_action = f"Kod üretildi: {language}"
        return code
    
    def debug_code(self, code: str, error: str) -> str:
        """Kod debug et"""
        prompt = f"""Şu kodda hata var:

```
{code}
```

Hata: {error}

Düzeltilmiş kodu ver."""
        
        fixed_code = self.llm.generate(prompt)
        return fixed_code
    
    def create_mql5_ea(self, strategy: str) -> str:
        """MQL5 Expert Advisor oluştur"""
        prompt = f"""MQL5 Expert Advisor yaz:

Strateji: {strategy}

İçermesi gerekenler:
1. OnInit(), OnDeinit(), OnTick() fonksiyonları
2. Risk yönetimi
3. Stop-loss ve take-profit
4. Input parametreleri"""
        
        ea_code = self.llm.generate(prompt)
        self.state.tasks_completed += 1
        return ea_code

# ============================================
# JOB HUNTER AGENT
# ============================================

class JobHunterAgent:
    """Freelance iş bulma ve yönetim agent"""
    
    def __init__(self, llm_client: OllamaClient):
        self.llm = llm_client
        self.state = AgentState(name="JobHunterAgent")
        self.jobs: List[Job] = []
        self.skills = [
            "Python", "AI/ML", "Trading Bot", 
            "MQL5", "Automation", "Data Analysis"
        ]
    
    def search_jobs(self, platform: str = "upwork", keywords: List[str] = None) -> List[Job]:
        """İş ara"""
        self.state.status = AgentStatus.WORKING
        
        if keywords is None:
            keywords = ["python", "ai", "automation", "trading bot"]
        
        # Gerçek implementasyonda API veya web scraping kullanılır
        # Şimdilik simüle ediyoruz
        sample_jobs = [
            Job(
                title="Python Trading Bot Developer",
                description="Need a trading bot for Binance",
                budget=500.0,
                platform=platform,
                url="https://upwork.com/job/123"
            ),
            Job(
                title="AI Automation Expert",
                description="Automate business processes with AI",
                budget=1000.0,
                platform=platform,
                url="https://upwork.com/job/456"
            )
        ]
        
        self.jobs.extend(sample_jobs)
        self.state.last_action = f"{len(sample_jobs)} iş bulundu"
        return sample_jobs
    
    def generate_proposal(self, job: Job) -> str:
        """İş için proposal oluştur"""
        prompt = f"""Şu iş için profesyonel bir proposal yaz:

Başlık: {job.title}
Açıklama: {job.description}
Bütçe: ${job.budget}

Benim becerilerim: {', '.join(self.skills)}

Proposal Türkçe ve kısa olsun."""
        
        proposal = self.llm.generate(prompt)
        job.proposal_sent = True
        return proposal
    
    def evaluate_job(self, job: Job) -> Dict:
        """İşin uygunluğunu değerlendir"""
        prompt = f"""Şu işi değerlendir:

{job.title}: {job.description}
Bütçe: ${job.budget}

Becerilerim: {', '.join(self.skills)}

1-10 arası puan ver ve neden uygun/uygun değil açıkla."""
        
        evaluation = self.llm.generate(prompt)
        return {"job": job.title, "evaluation": evaluation}

# ============================================
# SELF-LEARNING AGENT
# ============================================

class SelfLearningAgent:
    """Kendi kendini eğiten agent"""
    
    def __init__(self, llm_client: OllamaClient):
        self.llm = llm_client
        self.state = AgentState(name="SelfLearningAgent")
        self.knowledge_base: List[str] = []
        self.learning_log: List[Dict] = []
    
    def learn_from_experience(self, experience: Dict):
        """Deneyimden öğren"""
        self.state.status = AgentStatus.LEARNING
        
        summary = self.llm.generate(
            f"Bu deneyimden ne öğrendik? Özet çıkar:\n{json.dumps(experience, ensure_ascii=False)}"
        )
        
        self.knowledge_base.append(summary)
        self.learning_log.append({
            "timestamp": datetime.now().isoformat(),
            "experience": experience,
            "learning": summary
        })
        
        self.state.tasks_completed += 1
        self.state.last_action = "Yeni bilgi öğrenildi"
    
    def update_rag(self, new_data: str):
        """RAG veritabanını güncelle"""
        # Embedding oluştur ve kaydet
        self.knowledge_base.append(new_data)
        print(f"📚 RAG güncellendi: {len(new_data)} karakter")
    
    def self_improve(self):
        """Kendini geliştir"""
        if len(self.learning_log) < 5:
            return "Yeterli deneyim yok"
        
        recent = self.learning_log[-5:]
        prompt = f"""Son 5 deneyimi analiz et ve gelişim önerileri ver:

{json.dumps(recent, ensure_ascii=False, indent=2)}

Şu konularda öneri ver:
1. Trading stratejisi
2. Kod kalitesi
3. İş bulma başarısı"""
        
        improvements = self.llm.generate(prompt)
        return improvements
    
    def generate_training_data(self, topic: str, count: int = 10) -> List[Dict]:
        """Fine-tuning için eğitim verisi üret"""
        prompt = f"""'{topic}' konusunda {count} adet soru-cevap çifti oluştur.

Format:
{{"prompt": "soru", "completion": "cevap"}}

JSON dizisi olarak ver."""
        
        response = self.llm.generate(prompt)
        try:
            return json.loads(response)
        except:
            return []

# ============================================
# ANA ORKESTRATİR
# ============================================

class AutonomousAISystem:
    """Tüm agentları koordine eden ana sistem"""
    
    def __init__(self):
        self.llm = OllamaClient()
        self.trading_agent = TradingAgent(self.llm)
        self.coding_agent = CodingAgent(self.llm)
        self.job_hunter = JobHunterAgent(self.llm)
        self.learner = SelfLearningAgent(self.llm)
        
        self.running = False
        self.daily_report: Dict = {}
        self.total_earnings = 0.0
    
    def start(self):
        """Sistemi başlat"""
        print("=" * 50)
        print("  OTONOM AI GELİR SİSTEMİ BAŞLIYOR")
        print("=" * 50)
        
        self.running = True
        
        # Ana döngü
        while self.running:
            try:
                self._main_loop()
                time.sleep(60)  # 1 dakika bekle
            except KeyboardInterrupt:
                self.stop()
            except Exception as e:
                print(f"❌ Hata: {e}")
                self.learner.learn_from_experience({"error": str(e)})
    
    def stop(self):
        """Sistemi durdur"""
        self.running = False
        print("\n🛑 Sistem durduruluyor...")
        self._generate_report()
    
    def _main_loop(self):
        """Ana çalışma döngüsü"""
        now = datetime.now()
        
        # Her saat başı piyasa analizi
        if now.minute == 0:
            self._analyze_markets()
        
        # Her 4 saatte iş ara
        if now.hour % 4 == 0 and now.minute == 0:
            self._search_jobs()
        
        # Gece yarısı günlük rapor
        if now.hour == 0 and now.minute == 0:
            self._generate_report()
            self.learner.self_improve()
    
    def _analyze_markets(self):
        """Piyasa analizi yap"""
        symbols = ["BTC/USDT", "ETH/USDT", "SOL/USDT"]
        
        for symbol in symbols:
            analysis = self.trading_agent.analyze_market(symbol)
            print(f"📊 {symbol}: {analysis.get('signal', '')[:50]}...")
    
    def _search_jobs(self):
        """İş ara"""
        jobs = self.job_hunter.search_jobs("upwork")
        
        for job in jobs:
            eval_result = self.job_hunter.evaluate_job(job)
            if "8" in eval_result.get("evaluation", "") or "9" in eval_result.get("evaluation", "") or "10" in eval_result.get("evaluation", ""):
                proposal = self.job_hunter.generate_proposal(job)
                print(f"📝 Proposal hazır: {job.title}")
    
    def _generate_report(self):
        """Günlük rapor oluştur"""
        report = {
            "tarih": datetime.now().isoformat(),
            "trading": self.trading_agent.get_portfolio(),
            "coding": {
                "tasks": self.coding_agent.state.tasks_completed
            },
            "jobs": {
                "found": len(self.job_hunter.jobs),
                "proposals": sum(1 for j in self.job_hunter.jobs if j.proposal_sent)
            },
            "learning": {
                "knowledge_items": len(self.learner.knowledge_base)
            }
        }
        
        self.daily_report = report
        print("\n📋 GÜNLÜK RAPOR:")
        print(json.dumps(report, ensure_ascii=False, indent=2))
        
        return report
    
    def manual_trade(self, symbol: str, side: str, amount: float, exchange: str = "binance"):
        """Manuel trade yap"""
        return self.trading_agent.execute_trade(symbol, side, amount, exchange)
    
    def create_project(self, requirements: str):
        """Proje oluştur"""
        architecture = self.coding_agent.design_architecture(requirements)
        print(f"🏗️ Mimari:\n{architecture}")
        return architecture

# ============================================
# ÇALIŞTIRMA
# ============================================

def main():
    print("""
╔═══════════════════════════════════════════════════════════╗
║  OTONOM AI GELİR SİSTEMİ                                  ║
║  344Mehmet - Kendi Kendini Yöneten AI                     ║
╚═══════════════════════════════════════════════════════════╝
    """)
    
    system = AutonomousAISystem()
    
    # Test modu
    print("\n[1] Trading Agent Test")
    analysis = system.trading_agent.analyze_market("BTC/USDT")
    print(f"Analiz: {analysis.get('signal', '')[:100]}...")
    
    print("\n[2] Job Hunter Test")
    jobs = system.job_hunter.search_jobs()
    print(f"Bulunan iş sayısı: {len(jobs)}")
    
    print("\n[3] Coding Agent Test")
    arch = system.coding_agent.design_architecture("Telegram bot ile trading sinyalleri")
    print(f"Mimari: {arch[:200]}...")
    
    print("\n[4] Self-Learning Test")
    system.learner.learn_from_experience({"action": "test", "result": "success"})
    print(f"Öğrenilen bilgi sayısı: {len(system.learner.knowledge_base)}")
    
    print("\n" + "=" * 50)
    print("  TÜM TESTLER TAMAMLANDI!")
    print("=" * 50)
    
    # Sürekli çalışma için:
    # system.start()

if __name__ == "__main__":
    main()
