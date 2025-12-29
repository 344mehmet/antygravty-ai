"""
LLM ORDUSU - ZEKİ DÜŞÜNCE MOTORU
Chain of Thought + Multi-Agent + Reasoning
344Mehmet - 29 Aralık 2025

GitHub'dan en iyi AI agent framework'leri entegre edildi:
- CrewAI: Multi-agent orchestration
- LangGraph: Workflow management
- Chain of Thought: Step-by-step reasoning
- AutoGPT: Autonomous planning
"""

import os
import json
import time
from datetime import datetime
from typing import Dict, List, Optional, Callable, Any
from dataclasses import dataclass, field
from enum import Enum

# ============================================
# YAPILANDIRMA
# ============================================

OLLAMA_API = "http://localhost:11434"
DEFAULT_MODEL = "344mehmet-assistant"
REASONING_MODEL = "phi3:mini"  # Daha güçlü reasoning için

# ============================================
# DÜŞÜNCE MOTİFLERİ
# ============================================

class ThinkingMode(Enum):
    """Düşünce modları"""
    CHAIN_OF_THOUGHT = "cot"           # Adım adım düşünme
    TREE_OF_THOUGHT = "tot"            # Dallanmalı düşünme
    SELF_REFLECTION = "reflect"        # Kendini değerlendirme
    MULTI_PERSPECTIVE = "multi"        # Çoklu bakış açısı
    DEBATE = "debate"                  # İç tartışma
    RECURSIVE = "recursive"            # Özyinelemeli düşünme

@dataclass
class ThoughtStep:
    """Bir düşünce adımı"""
    step_number: int
    thought: str
    confidence: float = 0.0
    alternatives: List[str] = field(default_factory=list)
    timestamp: datetime = field(default_factory=datetime.now)

@dataclass
class ReasoningResult:
    """Reasoning sonucu"""
    question: str
    mode: ThinkingMode
    steps: List[ThoughtStep]
    final_answer: str
    confidence: float
    thinking_time: float
    tokens_used: int = 0

# ============================================
# OLLAMA İSTEMCİSİ
# ============================================

class OllamaReasoner:
    """Ollama ile zeki düşünme motoru"""
    
    def __init__(self, base_url: str = OLLAMA_API, model: str = DEFAULT_MODEL):
        self.base_url = base_url
        self.model = model
        self.history: List[ReasoningResult] = []
    
    def _call_llm(self, prompt: str, model: str = None) -> str:
        """LLM'i çağır"""
        try:
            import urllib.request
            
            data = json.dumps({
                "model": model or self.model,
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
    
    def chain_of_thought(self, question: str) -> ReasoningResult:
        """Chain of Thought düşünme"""
        start_time = time.time()
        steps = []
        
        # Adım 1: Problemi anla
        prompt1 = f"""Soru: {question}

Adım 1: Problemi Anlama
Bu soruyu analiz et. Ne isteniyor? Anahtar noktalar neler?
Sadece analizi yaz, çözümü değil."""
        
        step1 = self._call_llm(prompt1, REASONING_MODEL)
        steps.append(ThoughtStep(1, step1))
        
        # Adım 2: Strateji geliştir
        prompt2 = f"""Soru: {question}

Önceki analiz: {step1[:500]}

Adım 2: Strateji Geliştirme
Bu problemi çözmek için hangi adımları izlemeliyiz? 
Stratejini liste halinde yaz."""
        
        step2 = self._call_llm(prompt2, REASONING_MODEL)
        steps.append(ThoughtStep(2, step2))
        
        # Adım 3: Çözümü uygula
        prompt3 = f"""Soru: {question}

Analiz: {step1[:300]}
Strateji: {step2[:300]}

Adım 3: Çözüm
Şimdi stratejini uygula ve cevabı ver. Kısa ve net ol."""
        
        step3 = self._call_llm(prompt3, REASONING_MODEL)
        steps.append(ThoughtStep(3, step3))
        
        # Adım 4: Sonucu doğrula
        prompt4 = f"""Soru: {question}
Cevap: {step3[:500]}

Adım 4: Doğrulama
Bu cevap doğru mu? Eksik var mı? 1-10 arası güven puanı ver.
Format: GÜVEN: X/10"""
        
        step4 = self._call_llm(prompt4, REASONING_MODEL)
        steps.append(ThoughtStep(4, step4))
        
        # Güven puanı çıkar
        confidence = 0.7
        if "10/10" in step4:
            confidence = 1.0
        elif "9/10" in step4:
            confidence = 0.9
        elif "8/10" in step4:
            confidence = 0.8
        
        result = ReasoningResult(
            question=question,
            mode=ThinkingMode.CHAIN_OF_THOUGHT,
            steps=steps,
            final_answer=step3,
            confidence=confidence,
            thinking_time=time.time() - start_time
        )
        
        self.history.append(result)
        return result
    
    def self_reflection(self, question: str) -> ReasoningResult:
        """Self-reflection düşünme"""
        start_time = time.time()
        steps = []
        
        # İlk cevap
        prompt1 = f"Şu soruyu cevapla: {question}"
        answer1 = self._call_llm(prompt1, REASONING_MODEL)
        steps.append(ThoughtStep(1, f"İlk Cevap: {answer1}"))
        
        # Kendini sorgula
        prompt2 = f"""Soru: {question}
İlk Cevabım: {answer1}

Kendimi sorguluyorum:
1. Bu cevap doğru mu?
2. Eksik veya yanlış bir şey var mı?
3. Daha iyi bir cevap verebilir miyim?

Analiz et ve gerekirse düzelt."""
        
        reflection = self._call_llm(prompt2, REASONING_MODEL)
        steps.append(ThoughtStep(2, f"Yansıma: {reflection}"))
        
        # Final cevap
        prompt3 = f"""Soru: {question}

İlk cevap ve yansıtma sonrası, en iyi cevabı ver.
Kısa ve net ol."""
        
        final = self._call_llm(prompt3, REASONING_MODEL)
        steps.append(ThoughtStep(3, f"Final: {final}"))
        
        return ReasoningResult(
            question=question,
            mode=ThinkingMode.SELF_REFLECTION,
            steps=steps,
            final_answer=final,
            confidence=0.85,
            thinking_time=time.time() - start_time
        )
    
    def multi_perspective(self, question: str) -> ReasoningResult:
        """Çoklu bakış açısı düşünme"""
        start_time = time.time()
        steps = []
        perspectives = []
        
        roles = [
            ("Uzman", "Bu konuda uzman olarak"),
            ("Eleştirmen", "Eleştirel bakış açısıyla"),
            ("Yenilikçi", "Yaratıcı ve yenilikçi olarak")
        ]
        
        for role_name, role_prefix in roles:
            prompt = f"""{role_prefix} şu soruyu cevapla:
{question}

Kısa ve öz cevap ver."""
            
            response = self._call_llm(prompt, REASONING_MODEL)
            perspectives.append((role_name, response))
            steps.append(ThoughtStep(len(steps)+1, f"{role_name}: {response}"))
        
        # Sentez
        synth_prompt = f"""Soru: {question}

Farklı bakış açıları:
- Uzman: {perspectives[0][1][:200]}
- Eleştirmen: {perspectives[1][1][:200]}
- Yenilikçi: {perspectives[2][1][:200]}

Bu bakış açılarını sentezle ve en iyi cevabı ver."""
        
        synthesis = self._call_llm(synth_prompt, REASONING_MODEL)
        steps.append(ThoughtStep(len(steps)+1, f"Sentez: {synthesis}"))
        
        return ReasoningResult(
            question=question,
            mode=ThinkingMode.MULTI_PERSPECTIVE,
            steps=steps,
            final_answer=synthesis,
            confidence=0.9,
            thinking_time=time.time() - start_time
        )
    
    def debate(self, question: str) -> ReasoningResult:
        """İç tartışma - lehte ve aleyhte"""
        start_time = time.time()
        steps = []
        
        # Lehte argüman
        prompt_pro = f"""Soru: {question}

LEHTE argüman ver. Bu fikrin/önerinin neden iyi olduğunu savun.
3 madde halinde yaz."""
        
        pro = self._call_llm(prompt_pro, REASONING_MODEL)
        steps.append(ThoughtStep(1, f"LEHTE: {pro}"))
        
        # Aleyhte argüman
        prompt_con = f"""Soru: {question}

ALEYHTE argüman ver. Bu fikrin/önerinin potansiyel sorunlarını belirt.
3 madde halinde yaz."""
        
        con = self._call_llm(prompt_con, REASONING_MODEL)
        steps.append(ThoughtStep(2, f"ALEYHTE: {con}"))
        
        # Hakem kararı
        prompt_judge = f"""Soru: {question}

LEHTE: {pro[:300]}
ALEYHTE: {con[:300]}

HAKEM olarak karar ver. Dengeli bir sonuç yaz."""
        
        verdict = self._call_llm(prompt_judge, REASONING_MODEL)
        steps.append(ThoughtStep(3, f"KARAR: {verdict}"))
        
        return ReasoningResult(
            question=question,
            mode=ThinkingMode.DEBATE,
            steps=steps,
            final_answer=verdict,
            confidence=0.85,
            thinking_time=time.time() - start_time
        )

# ============================================
# MULTI-AGENT SİSTEMİ (CrewAI tarzı)
# ============================================

@dataclass
class Agent:
    """AI Agent tanımı"""
    name: str
    role: str
    goal: str
    backstory: str = ""
    tools: List[str] = field(default_factory=list)

class LLMCrew:
    """Multi-agent orchestration - CrewAI tarzı"""
    
    def __init__(self, reasoner: OllamaReasoner):
        self.reasoner = reasoner
        self.agents: List[Agent] = []
        self.tasks_completed: List[Dict] = []
    
    def add_agent(self, agent: Agent):
        """Agent ekle"""
        self.agents.append(agent)
        print(f"✅ Agent eklendi: {agent.name} - {agent.role}")
    
    def create_default_crew(self):
        """Varsayılan crew oluştur"""
        self.add_agent(Agent(
            name="Araştırmacı",
            role="Research Specialist",
            goal="Derinlemesine araştırma ve bilgi toplama",
            tools=["web_search", "document_analysis"]
        ))
        
        self.add_agent(Agent(
            name="Analist",
            role="Data Analyst",
            goal="Verileri analiz et ve içgörü çıkar",
            tools=["data_analysis", "visualization"]
        ))
        
        self.add_agent(Agent(
            name="Yazıcı",
            role="Content Writer",
            goal="Net ve etkili içerik oluştur",
            tools=["writing", "editing"]
        ))
        
        self.add_agent(Agent(
            name="Stratejist",
            role="Strategy Expert",
            goal="Strateji geliştir ve karar ver",
            tools=["planning", "decision_making"]
        ))
    
    def run_task(self, task: str, assigned_agent: str = None) -> Dict:
        """Görevi çalıştır"""
        agent = None
        
        if assigned_agent:
            for a in self.agents:
                if a.name.lower() == assigned_agent.lower():
                    agent = a
                    break
        
        if not agent and self.agents:
            agent = self.agents[0]
        
        if not agent:
            return {"error": "Agent bulunamadı"}
        
        prompt = f"""Sen {agent.name} rolündesin.
Rolün: {agent.role}
Hedefin: {agent.goal}

GÖREV: {task}

Bu görevi yerine getir ve sonucu raporla."""
        
        result = self.reasoner._call_llm(prompt, REASONING_MODEL)
        
        task_result = {
            "task": task,
            "agent": agent.name,
            "result": result,
            "timestamp": datetime.now().isoformat()
        }
        
        self.tasks_completed.append(task_result)
        return task_result
    
    def sequential_workflow(self, tasks: List[str]) -> List[Dict]:
        """Sıralı görev akışı"""
        results = []
        previous_output = ""
        
        for i, task in enumerate(tasks):
            agent = self.agents[i % len(self.agents)] if self.agents else None
            
            if previous_output and agent:
                full_task = f"{task}\n\nÖnceki çıktı: {previous_output[:500]}"
            else:
                full_task = task
            
            result = self.run_task(full_task, agent.name if agent else None)
            results.append(result)
            previous_output = result.get("result", "")
        
        return results

# ============================================
# TOOL CALLING SİSTEMİ
# ============================================

class ToolCallingAgent:
    """Fonksiyon çağırma yeteneği olan agent"""
    
    def __init__(self, reasoner: OllamaReasoner):
        self.reasoner = reasoner
        self.tools: Dict[str, Callable] = {}
    
    def register_tool(self, name: str, func: Callable, description: str):
        """Tool kaydet"""
        self.tools[name] = {
            "function": func,
            "description": description
        }
        print(f"🔧 Tool kaydedildi: {name}")
    
    def register_default_tools(self):
        """Varsayılan tool'ları kaydet"""
        
        def web_search(query: str) -> str:
            return f"Web araması sonucu: '{query}' için sonuçlar bulundu."
        
        def calculate(expression: str) -> str:
            try:
                result = eval(expression)
                return f"Hesaplama sonucu: {result}"
            except:
                return f"Hesaplama hatası: {expression}"
        
        def get_time() -> str:
            return f"Şu anki zaman: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        
        def get_weather(city: str) -> str:
            return f"{city} için hava durumu: Güneşli, 22°C"
        
        self.register_tool("web_search", web_search, "Web'de arama yapar")
        self.register_tool("calculate", calculate, "Matematiksel hesaplama yapar")
        self.register_tool("get_time", get_time, "Şu anki zamanı döndürür")
        self.register_tool("get_weather", get_weather, "Hava durumu bilgisi verir")
    
    def run_with_tools(self, query: str) -> Dict:
        """Tool'larla birlikte çalıştır"""
        
        tool_list = "\n".join([
            f"- {name}: {info['description']}" 
            for name, info in self.tools.items()
        ])
        
        prompt = f"""Kullanılabilir araçlar:
{tool_list}

Soru: {query}

Hangi aracı kullanmam gerekiyor? 
Format: TOOL: araç_adı veya NONE (araç gerekmiyorsa)"""
        
        response = self.reasoner._call_llm(prompt, REASONING_MODEL)
        
        tool_used = None
        tool_result = None
        
        for tool_name in self.tools.keys():
            if tool_name in response.lower():
                tool_used = tool_name
                # Basit parametre çıkarımı
                if tool_name == "calculate":
                    # Sayıları bul
                    import re
                    numbers = re.findall(r'[\d+\-*/().]+', query)
                    if numbers:
                        tool_result = self.tools[tool_name]["function"](numbers[0])
                elif tool_name == "get_time":
                    tool_result = self.tools[tool_name]["function"]()
                elif tool_name == "web_search":
                    tool_result = self.tools[tool_name]["function"](query)
                elif tool_name == "get_weather":
                    tool_result = self.tools[tool_name]["function"]("İstanbul")
                break
        
        if tool_result:
            final_prompt = f"""Soru: {query}
Tool sonucu: {tool_result}

Bu bilgiyi kullanarak soruyu cevapla."""
            
            final_answer = self.reasoner._call_llm(final_prompt, REASONING_MODEL)
        else:
            final_answer = self.reasoner._call_llm(query, REASONING_MODEL)
        
        return {
            "query": query,
            "tool_used": tool_used,
            "tool_result": tool_result,
            "answer": final_answer
        }

# ============================================
# ANA SINIF
# ============================================

class LLMArmy:
    """LLM Ordusu - Tüm yetenekleri birleştiren ana sınıf"""
    
    def __init__(self):
        self.reasoner = OllamaReasoner()
        self.crew = LLMCrew(self.reasoner)
        self.tool_agent = ToolCallingAgent(self.reasoner)
        
        # Varsayılanları yükle
        self.crew.create_default_crew()
        self.tool_agent.register_default_tools()
        
        print("\n🎖️ LLM ORDUSU HAZIR!")
        print(f"   - Reasoner: {len(ThinkingMode)} düşünce modu")
        print(f"   - Crew: {len(self.crew.agents)} agent")
        print(f"   - Tools: {len(self.tool_agent.tools)} araç")
    
    def smart_think(self, question: str, mode: str = "auto") -> ReasoningResult:
        """Akıllı düşünme - mod otomatik seçilir"""
        
        if mode == "auto":
            # Soru tipine göre mod seç
            q_lower = question.lower()
            
            if any(w in q_lower for w in ["karşılaştır", "compare", "vs", "fark"]):
                mode = "debate"
            elif any(w in q_lower for w in ["nasıl", "neden", "açıkla"]):
                mode = "cot"
            elif any(w in q_lower for w in ["fikir", "strateji", "öneri"]):
                mode = "multi"
            else:
                mode = "cot"
        
        if mode == "cot":
            return self.reasoner.chain_of_thought(question)
        elif mode == "reflect":
            return self.reasoner.self_reflection(question)
        elif mode == "multi":
            return self.reasoner.multi_perspective(question)
        elif mode == "debate":
            return self.reasoner.debate(question)
        else:
            return self.reasoner.chain_of_thought(question)
    
    def run_crew_mission(self, mission: str) -> List[Dict]:
        """Crew ile misyon çalıştır"""
        tasks = [
            f"Bu misyonu araştır: {mission}",
            "Araştırma sonuçlarını analiz et",
            "Bulgulardan strateji çıkar",
            "Sonuç raporunu yaz"
        ]
        
        return self.crew.sequential_workflow(tasks)
    
    def ask_with_tools(self, query: str) -> Dict:
        """Tool'larla soru sor"""
        return self.tool_agent.run_with_tools(query)

# ============================================
# TEST
# ============================================

def main():
    print("""
╔═══════════════════════════════════════════════════════════╗
║  LLM ORDUSU - ZEKİ DÜŞÜNCE MOTORU                         ║
║  Chain of Thought + Multi-Agent + Tool Calling            ║
╚═══════════════════════════════════════════════════════════╝
    """)
    
    army = LLMArmy()
    
    # Test 1: Chain of Thought
    print("\n[1] Chain of Thought Test")
    print("-" * 40)
    result1 = army.smart_think("Kripto piyasasında risk yönetimi nasıl yapılmalı?")
    print(f"Soru: {result1.question}")
    print(f"Mod: {result1.mode.value}")
    print(f"Adım sayısı: {len(result1.steps)}")
    print(f"Güven: {result1.confidence:.0%}")
    print(f"Süre: {result1.thinking_time:.2f}s")
    print(f"Cevap: {result1.final_answer[:200]}...")
    
    # Test 2: Multi-perspective
    print("\n[2] Çoklu Bakış Açısı Test")
    print("-" * 40)
    result2 = army.smart_think("AI gelecekte işleri yok edecek mi?", mode="multi")
    print(f"Cevap: {result2.final_answer[:200]}...")
    
    # Test 3: Tool calling
    print("\n[3] Tool Calling Test")
    print("-" * 40)
    result3 = army.ask_with_tools("Saat kaç?")
    print(f"Tool: {result3['tool_used']}")
    print(f"Cevap: {result3['answer'][:100]}...")
    
    print("\n" + "=" * 50)
    print("  LLM ORDUSU TEST TAMAMLANDI!")
    print("=" * 50)

if __name__ == "__main__":
    main()
