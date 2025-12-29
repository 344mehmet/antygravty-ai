"""
ChromaDB ile RAG Sistemi - Windows için Hazır Versiyon
344Mehmet AI Asistan
29 Aralık 2025
"""

import os
import json
import subprocess

# Ollama API
OLLAMA_API = "http://localhost:11434"
OLLAMA_CMD = os.path.expanduser("~\\AppData\\Local\\Programs\\Ollama\\ollama.exe")

def check_ollama():
    """Ollama durumunu kontrol et"""
    try:
        import urllib.request
        req = urllib.request.Request(f"{OLLAMA_API}/api/tags")
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            models = data.get("models", [])
            print(f"✓ Ollama çalışıyor - {len(models)} model yüklü")
            for m in models:
                print(f"  - {m.get('name')}")
            return True
    except Exception as e:
        print(f"✗ Ollama hatası: {e}")
        return False

def generate_response(prompt, model="344mehmet-assistant"):
    """Ollama'dan yanıt al"""
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
            return result.get("response", "")
    except Exception as e:
        return f"Hata: {e}"

def generate_embedding(text, model="nomic-embed-text"):
    """Embedding oluştur"""
    try:
        import urllib.request
        
        data = json.dumps({
            "model": model,
            "prompt": text
        }).encode('utf-8')
        
        req = urllib.request.Request(
            f"{OLLAMA_API}/api/embeddings",
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        
        with urllib.request.urlopen(req, timeout=60) as response:
            result = json.loads(response.read().decode())
            return result.get("embedding", [])
    except Exception as e:
        print(f"Embedding hatası: {e}")
        return []

class SimpleVectorStore:
    """Basit vektör deposu (ChromaDB olmadan)"""
    
    def __init__(self, store_path=None):
        self.store_path = store_path or os.path.expanduser("~/.rag_store.json")
        self.documents = []
        self.embeddings = []
        self.load()
    
    def load(self):
        """Depoyu yükle"""
        if os.path.exists(self.store_path):
            try:
                with open(self.store_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self.documents = data.get('documents', [])
                    self.embeddings = data.get('embeddings', [])
                print(f"✓ {len(self.documents)} belge yüklendi")
            except:
                pass
    
    def save(self):
        """Depoyu kaydet"""
        with open(self.store_path, 'w', encoding='utf-8') as f:
            json.dump({
                'documents': self.documents,
                'embeddings': self.embeddings
            }, f, ensure_ascii=False)
    
    def add(self, text):
        """Belge ekle"""
        embedding = generate_embedding(text)
        if embedding:
            self.documents.append(text)
            self.embeddings.append(embedding)
            self.save()
            print(f"✓ Belge eklendi ({len(text)} karakter)")
            return True
        return False
    
    def search(self, query, top_k=3):
        """En benzer belgeleri bul"""
        if not self.embeddings:
            return []
        
        query_embedding = generate_embedding(query)
        if not query_embedding:
            return []
        
        # Cosine similarity hesapla
        scores = []
        for i, emb in enumerate(self.embeddings):
            similarity = self._cosine_similarity(query_embedding, emb)
            scores.append((similarity, i))
        
        # En yüksek skorları al
        scores.sort(reverse=True)
        results = []
        for score, idx in scores[:top_k]:
            results.append({
                'text': self.documents[idx],
                'score': score
            })
        
        return results
    
    def _cosine_similarity(self, a, b):
        """Cosine benzerliği hesapla"""
        if len(a) != len(b):
            return 0
        
        dot_product = sum(x * y for x, y in zip(a, b))
        norm_a = sum(x * x for x in a) ** 0.5
        norm_b = sum(x * x for x in b) ** 0.5
        
        if norm_a == 0 or norm_b == 0:
            return 0
        
        return dot_product / (norm_a * norm_b)

def rag_query(question, store=None, model="344mehmet-assistant"):
    """RAG ile soru sor"""
    if store is None:
        store = SimpleVectorStore()
    
    # İlgili belgeleri bul
    results = store.search(question, top_k=3)
    
    if results:
        context = "\n\n".join([f"Belge {i+1}: {r['text']}" for i, r in enumerate(results)])
        prompt = f"""Aşağıdaki bağlamı kullanarak soruyu cevapla.

BAĞLAM:
{context}

SORU: {question}

CEVAP:"""
    else:
        prompt = question
    
    return generate_response(prompt, model)

def interactive_mode():
    """Etkileşimli mod"""
    print("\n" + "="*50)
    print("  344Mehmet RAG Sistemi - Etkileşimli Mod")
    print("="*50)
    print("\nKomutlar:")
    print("  /add <metin> - Belge ekle")
    print("  /search <sorgu> - Belge ara")
    print("  /list - Belgeleri listele")
    print("  /exit - Çıkış")
    print()
    
    store = SimpleVectorStore()
    
    while True:
        try:
            user_input = input("Soru: ").strip()
            
            if not user_input:
                continue
            
            if user_input.startswith("/add "):
                text = user_input[5:]
                store.add(text)
            
            elif user_input.startswith("/search "):
                query = user_input[8:]
                results = store.search(query)
                for i, r in enumerate(results):
                    print(f"\n[{i+1}] Skor: {r['score']:.3f}")
                    print(f"    {r['text'][:100]}...")
            
            elif user_input == "/list":
                print(f"\n{len(store.documents)} belge kayıtlı:")
                for i, doc in enumerate(store.documents[:10]):
                    print(f"  {i+1}. {doc[:50]}...")
            
            elif user_input == "/exit":
                break
            
            else:
                # RAG sorgusu
                response = rag_query(user_input, store)
                print(f"\nCevap: {response}\n")
        
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"Hata: {e}")

if __name__ == "__main__":
    print("="*50)
    print("  344Mehmet RAG Sistemi")
    print("="*50)
    print()
    
    # Ollama kontrol
    if check_ollama():
        print()
        interactive_mode()
    else:
        print("\nOllama'yı başlatın: ollama serve")
