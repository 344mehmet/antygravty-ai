"""
LLM ORDUSU - MOBİL WEB UYGULAMASI
FastAPI + Düşünce Motoru + QR Kod Erişimi
344Mehmet - 29 Aralık 2025
"""

import os
import io
import json
import base64
import socket
import time
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass

# FastAPI yerine built-in HTTP server kullanıyoruz (bağımlılık yok)
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading

# ============================================
# YAPILANDIRMA
# ============================================

OLLAMA_API = "http://localhost:11434"
DEFAULT_MODEL = "344mehmet-assistant"
REASONING_MODEL = "phi3:mini"
SERVER_PORT = 8080

# ============================================
# QR KOD ÜRETİCİ (ASCII tabanlı - bağımlılık yok)
# ============================================

def generate_qr_ascii(data: str) -> str:
    """Basit ASCII QR benzeri görsel oluştur"""
    # Gerçek QR için qrcode kütüphanesi gerekir
    # Bu basit bir placeholder
    lines = [
        "█████████████████████████",
        "█                       █",
        f"█  {data[:20]:<20} █",
        "█                       █",
        "█  ███  █ █ █  ███      █",
        "█  █ █  █████  █ █      █",
        "█  ███  █ █ █  ███      █",
        "█                       █",
        "█████████████████████████",
    ]
    return "\n".join(lines)

def generate_qr_html(url: str) -> str:
    """QR kod için HTML (Google Charts API kullanarak)"""
    encoded_url = url.replace("&", "%26").replace("?", "%3F")
    return f'''
    <div style="text-align: center; margin: 20px;">
        <img src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data={encoded_url}" 
             alt="QR Code" style="border: 2px solid #333; border-radius: 10px;">
        <p style="margin-top: 10px; font-size: 14px; color: #666;">{url}</p>
    </div>
    '''

# ============================================
# OLLAMA İSTEMCİSİ
# ============================================

def call_ollama(prompt: str, model: str = DEFAULT_MODEL) -> str:
    """Ollama API çağrısı"""
    try:
        import urllib.request
        
        data = json.dumps({
            "model": model,
            "prompt": prompt,
            "stream": False
        }).encode('utf-8')
        
        req = urllib.request.Request(
            f"{OLLAMA_API}/api/generate",
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        
        with urllib.request.urlopen(req, timeout=120) as response:
            result = json.loads(response.read().decode())
            return result.get("response", "Cevap alınamadı")
    except Exception as e:
        return f"Hata: {e}"

def chain_of_thought(question: str) -> Dict:
    """Chain of Thought düşünme"""
    steps = []
    
    # Adım 1
    prompt1 = f"Soru: {question}\n\nAdım 1: Bu soruyu analiz et. Ne isteniyor?"
    step1 = call_ollama(prompt1, REASONING_MODEL)
    steps.append({"step": 1, "title": "Analiz", "content": step1})
    
    # Adım 2
    prompt2 = f"Soru: {question}\nAnaliz: {step1[:300]}\n\nAdım 2: Stratejini belirle."
    step2 = call_ollama(prompt2, REASONING_MODEL)
    steps.append({"step": 2, "title": "Strateji", "content": step2})
    
    # Adım 3
    prompt3 = f"Soru: {question}\nStrateji: {step2[:300]}\n\nAdım 3: Cevabı ver."
    step3 = call_ollama(prompt3, REASONING_MODEL)
    steps.append({"step": 3, "title": "Cevap", "content": step3})
    
    return {
        "question": question,
        "steps": steps,
        "final_answer": step3
    }

# ============================================
# HTML ŞABLONLARI
# ============================================

def get_main_html(server_ip: str, port: int) -> str:
    """Ana sayfa HTML"""
    qr_html = generate_qr_html(f"http://{server_ip}:{port}")
    
    return f'''<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🤖 LLM Ordusu - Zeki Düşünce Motoru</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            min-height: 100vh;
            color: #fff;
        }}
        
        .container {{
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }}
        
        header {{
            text-align: center;
            padding: 30px 0;
        }}
        
        h1 {{
            font-size: 2rem;
            background: linear-gradient(45deg, #00d4ff, #7c3aed);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 10px;
        }}
        
        .subtitle {{
            color: #888;
            font-size: 0.9rem;
        }}
        
        .card {{
            background: rgba(255, 255, 255, 0.05);
            border-radius: 16px;
            padding: 20px;
            margin: 20px 0;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }}
        
        .input-group {{
            display: flex;
            gap: 10px;
            margin: 20px 0;
        }}
        
        input[type="text"] {{
            flex: 1;
            padding: 15px;
            border: none;
            border-radius: 12px;
            background: rgba(255, 255, 255, 0.1);
            color: #fff;
            font-size: 16px;
        }}
        
        input[type="text"]::placeholder {{
            color: #666;
        }}
        
        button {{
            padding: 15px 30px;
            border: none;
            border-radius: 12px;
            background: linear-gradient(45deg, #00d4ff, #7c3aed);
            color: #fff;
            font-size: 16px;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }}
        
        button:hover {{
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(0, 212, 255, 0.3);
        }}
        
        button:disabled {{
            opacity: 0.5;
            cursor: not-allowed;
        }}
        
        .mode-selector {{
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin: 15px 0;
        }}
        
        .mode-btn {{
            padding: 10px 20px;
            border-radius: 8px;
            background: rgba(255, 255, 255, 0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            color: #fff;
            cursor: pointer;
            transition: all 0.2s;
        }}
        
        .mode-btn.active {{
            background: linear-gradient(45deg, #00d4ff, #7c3aed);
            border-color: transparent;
        }}
        
        .result {{
            margin-top: 20px;
            padding: 20px;
            background: rgba(0, 212, 255, 0.1);
            border-radius: 12px;
            border-left: 4px solid #00d4ff;
        }}
        
        .step {{
            padding: 15px;
            margin: 10px 0;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 8px;
        }}
        
        .step-title {{
            color: #00d4ff;
            font-weight: bold;
            margin-bottom: 10px;
        }}
        
        .loading {{
            display: none;
            text-align: center;
            padding: 30px;
        }}
        
        .loading.show {{
            display: block;
        }}
        
        .spinner {{
            width: 40px;
            height: 40px;
            border: 4px solid rgba(255, 255, 255, 0.1);
            border-top-color: #00d4ff;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 0 auto 15px;
        }}
        
        @keyframes spin {{
            to {{ transform: rotate(360deg); }}
        }}
        
        .qr-section {{
            text-align: center;
            padding: 20px;
        }}
        
        .features {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }}
        
        .feature {{
            text-align: center;
            padding: 20px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 12px;
        }}
        
        .feature-icon {{
            font-size: 2rem;
            margin-bottom: 10px;
        }}
        
        .footer {{
            text-align: center;
            padding: 20px;
            color: #666;
            font-size: 0.8rem;
        }}
        
        @media (max-width: 600px) {{
            h1 {{
                font-size: 1.5rem;
            }}
            
            .input-group {{
                flex-direction: column;
            }}
            
            button {{
                width: 100%;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🤖 LLM Ordusu</h1>
            <p class="subtitle">Zeki Düşünce Motoru - 344Mehmet</p>
        </header>
        
        <div class="card">
            <h2>💭 Düşünce Modları</h2>
            <div class="mode-selector">
                <button class="mode-btn active" data-mode="cot">🔗 Chain of Thought</button>
                <button class="mode-btn" data-mode="simple">⚡ Hızlı Cevap</button>
                <button class="mode-btn" data-mode="multi">👥 Çoklu Bakış</button>
            </div>
            
            <div class="input-group">
                <input type="text" id="question" placeholder="Sorunuzu yazın..." />
                <button onclick="askQuestion()">Sor</button>
            </div>
            
            <div class="loading" id="loading">
                <div class="spinner"></div>
                <p>AI düşünüyor...</p>
            </div>
            
            <div id="result"></div>
        </div>
        
        <div class="card">
            <h2>📱 Mobil Erişim</h2>
            <div class="qr-section">
                {qr_html}
                <p>Bu QR kodu telefonunuzla tarayarak uygulamaya erişebilirsiniz.</p>
            </div>
        </div>
        
        <div class="card">
            <h2>🎖️ Özellikler</h2>
            <div class="features">
                <div class="feature">
                    <div class="feature-icon">🧠</div>
                    <div>Chain of Thought</div>
                </div>
                <div class="feature">
                    <div class="feature-icon">🤖</div>
                    <div>Multi-Agent</div>
                </div>
                <div class="feature">
                    <div class="feature-icon">📊</div>
                    <div>Trading Sinyali</div>
                </div>
                <div class="feature">
                    <div class="feature-icon">💻</div>
                    <div>Kod Üretimi</div>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p>LLM Ordusu v1.0 | 344Mehmet | Ollama + Local LLM</p>
        </div>
    </div>
    
    <script>
        let currentMode = 'cot';
        
        document.querySelectorAll('.mode-btn').forEach(btn => {{
            btn.addEventListener('click', () => {{
                document.querySelectorAll('.mode-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                currentMode = btn.dataset.mode;
            }});
        }});
        
        async function askQuestion() {{
            const question = document.getElementById('question').value;
            if (!question) return;
            
            const loading = document.getElementById('loading');
            const result = document.getElementById('result');
            
            loading.classList.add('show');
            result.innerHTML = '';
            
            try {{
                const response = await fetch('/api/think?q=' + encodeURIComponent(question) + '&mode=' + currentMode);
                const data = await response.json();
                
                if (data.steps) {{
                    let html = '';
                    data.steps.forEach(step => {{
                        html += `
                            <div class="step">
                                <div class="step-title">Adım ${{step.step}}: ${{step.title}}</div>
                                <div>${{step.content}}</div>
                            </div>
                        `;
                    }});
                    html += `<div class="result"><strong>Final Cevap:</strong><br>${{data.final_answer}}</div>`;
                    result.innerHTML = html;
                }} else {{
                    result.innerHTML = `<div class="result">${{data.answer || data.error}}</div>`;
                }}
            }} catch (e) {{
                result.innerHTML = `<div class="result">Hata: ${{e.message}}</div>`;
            }}
            
            loading.classList.remove('show');
        }}
        
        document.getElementById('question').addEventListener('keypress', (e) => {{
            if (e.key === 'Enter') askQuestion();
        }});
    </script>
</body>
</html>'''

# ============================================
# HTTP SUNUCU
# ============================================

class LLMHandler(BaseHTTPRequestHandler):
    """HTTP istek işleyici"""
    
    server_ip = "localhost"
    
    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)
        
        if path == "/" or path == "/index.html":
            self.send_html(get_main_html(self.server_ip, SERVER_PORT))
        
        elif path == "/api/think":
            question = query.get("q", [""])[0]
            mode = query.get("mode", ["cot"])[0]
            
            if not question:
                self.send_json({"error": "Soru gerekli"})
                return
            
            if mode == "cot":
                result = chain_of_thought(question)
            else:
                answer = call_ollama(question)
                result = {"answer": answer}
            
            self.send_json(result)
        
        elif path == "/api/status":
            self.send_json({
                "status": "online",
                "model": DEFAULT_MODEL,
                "timestamp": datetime.now().isoformat()
            })
        
        elif path == "/api/models":
            # Ollama modellerini listele
            try:
                import urllib.request
                with urllib.request.urlopen(f"{OLLAMA_API}/api/tags", timeout=10) as resp:
                    data = json.loads(resp.read().decode())
                    self.send_json(data)
            except:
                self.send_json({"models": []})
        
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not Found")
    
    def send_html(self, content):
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(content.encode('utf-8'))
    
    def send_json(self, data):
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))
    
    def log_message(self, format, *args):
        print(f"[{datetime.now().strftime('%H:%M:%S')}] {args[0]}")

# ============================================
# YARDIMCI FONKSİYONLAR
# ============================================

def get_local_ip() -> str:
    """Yerel IP adresini bul"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

# ============================================
# ANA FONKSİYON
# ============================================

def main():
    local_ip = get_local_ip()
    LLMHandler.server_ip = local_ip
    
    print("""
╔═══════════════════════════════════════════════════════════╗
║  LLM ORDUSU - MOBİL WEB UYGULAMASI                        ║
║  FastAPI + Düşünce Motoru + QR Erişim                     ║
╚═══════════════════════════════════════════════════════════╝
    """)
    
    print(f"🌐 Sunucu başlatılıyor...")
    print(f"")
    print(f"📱 MOBİL ERİŞİM:")
    print(f"   Yerel:  http://localhost:{SERVER_PORT}")
    print(f"   Ağ:     http://{local_ip}:{SERVER_PORT}")
    print(f"")
    print(f"📲 QR KOD:")
    print(generate_qr_ascii(f"http://{local_ip}:{SERVER_PORT}"))
    print(f"")
    print(f"   Telefonunuzdan bu adresi açın:")
    print(f"   http://{local_ip}:{SERVER_PORT}")
    print(f"")
    print(f"⏹️  Durdurmak için Ctrl+C")
    print(f"")
    
    try:
        server = HTTPServer(("0.0.0.0", SERVER_PORT), LLMHandler)
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Sunucu durduruldu.")
    except Exception as e:
        print(f"❌ Hata: {e}")

if __name__ == "__main__":
    main()
