/*
LLM ORDUSU - GO API SERVER
Gin Framework + Düşünce Motoru + Mobil Erişim
344Mehmet - 29 Aralık 2025

Çalıştırmak için:
  go mod init llm-army
  go get -u github.com/gin-gonic/gin
  go run main.go
*/

package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"time"
)

// ============================================
// YAPILANDIRMA
// ============================================

const (
	OllamaAPI    = "http://localhost:11434"
	DefaultModel = "344mehmet-assistant"
	ServerPort   = "8081" // Python 8080 kullandığı için farklı port
)

// ============================================
// VERİ YAPILARI
// ============================================

type OllamaRequest struct {
	Model  string `json:"model"`
	Prompt string `json:"prompt"`
	Stream bool   `json:"stream"`
}

type OllamaResponse struct {
	Response string `json:"response"`
}

type ThinkStep struct {
	Step    int    `json:"step"`
	Title   string `json:"title"`
	Content string `json:"content"`
}

type ThinkResult struct {
	Question    string      `json:"question"`
	Steps       []ThinkStep `json:"steps"`
	FinalAnswer string      `json:"final_answer"`
	ThinkingMs  int64       `json:"thinking_ms"`
}

type StatusResponse struct {
	Status    string `json:"status"`
	Model     string `json:"model"`
	Timestamp string `json:"timestamp"`
	GoVersion string `json:"go_version"`
}

// ============================================
// OLLAMA İSTEMCİSİ
// ============================================

func callOllama(prompt string, model string) (string, error) {
	if model == "" {
		model = DefaultModel
	}

	reqBody := OllamaRequest{
		Model:  model,
		Prompt: prompt,
		Stream: false,
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return "", err
	}

	client := &http.Client{Timeout: 120 * time.Second}
	resp, err := client.Post(
		OllamaAPI+"/api/generate",
		"application/json",
		bytes.NewBuffer(jsonData),
	)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	var ollamaResp OllamaResponse
	err = json.Unmarshal(body, &ollamaResp)
	if err != nil {
		return "", err
	}

	return ollamaResp.Response, nil
}

// ============================================
// DÜŞÜNCE MOTORU
// ============================================

func chainOfThought(question string) ThinkResult {
	start := time.Now()
	steps := []ThinkStep{}

	// Adım 1: Analiz
	prompt1 := fmt.Sprintf("Soru: %s\n\nAdım 1: Bu soruyu analiz et. Ne isteniyor?", question)
	step1, _ := callOllama(prompt1, "phi3:mini")
	steps = append(steps, ThinkStep{Step: 1, Title: "Analiz", Content: step1})

	// Adım 2: Strateji
	prompt2 := fmt.Sprintf("Soru: %s\nAnaliz: %s\n\nAdım 2: Stratejini belirle.", question, truncate(step1, 300))
	step2, _ := callOllama(prompt2, "phi3:mini")
	steps = append(steps, ThinkStep{Step: 2, Title: "Strateji", Content: step2})

	// Adım 3: Cevap
	prompt3 := fmt.Sprintf("Soru: %s\nStrateji: %s\n\nAdım 3: Cevabı ver.", question, truncate(step2, 300))
	step3, _ := callOllama(prompt3, "phi3:mini")
	steps = append(steps, ThinkStep{Step: 3, Title: "Cevap", Content: step3})

	elapsed := time.Since(start).Milliseconds()

	return ThinkResult{
		Question:    question,
		Steps:       steps,
		FinalAnswer: step3,
		ThinkingMs:  elapsed,
	}
}

func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}

// ============================================
// YARDIMCI FONKSİYONLAR
// ============================================

func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "127.0.0.1"
	}

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}
	return "127.0.0.1"
}

func generateQRURL(url string) string {
	return fmt.Sprintf("https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=%s", url)
}

// ============================================
// HTML ŞABLONU
// ============================================

func getMainHTML(serverIP string) string {
	qrURL := generateQRURL(fmt.Sprintf("http://%s:%s", serverIP, ServerPort))

	return fmt.Sprintf(`<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🤖 LLM Ordusu - Go API</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f0c29 0%%, #302b63 50%%, #24243e 100%%);
            min-height: 100vh;
            color: #fff;
        }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; }
        header { text-align: center; padding: 30px 0; }
        h1 {
            font-size: 2rem;
            background: linear-gradient(45deg, #f093fb, #f5576c);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .badge { display: inline-block; padding: 5px 15px; background: rgba(240,147,251,0.2); border-radius: 20px; margin-top: 10px; }
        .card {
            background: rgba(255, 255, 255, 0.05);
            border-radius: 16px;
            padding: 20px;
            margin: 20px 0;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        .input-group { display: flex; gap: 10px; margin: 20px 0; flex-wrap: wrap; }
        input[type="text"] {
            flex: 1;
            min-width: 200px;
            padding: 15px;
            border: none;
            border-radius: 12px;
            background: rgba(255, 255, 255, 0.1);
            color: #fff;
            font-size: 16px;
        }
        button {
            padding: 15px 30px;
            border: none;
            border-radius: 12px;
            background: linear-gradient(45deg, #f093fb, #f5576c);
            color: #fff;
            font-size: 16px;
            cursor: pointer;
            transition: transform 0.2s;
        }
        button:hover { transform: translateY(-2px); }
        .result { margin-top: 20px; padding: 20px; background: rgba(240,147,251,0.1); border-radius: 12px; }
        .step { padding: 15px; margin: 10px 0; background: rgba(255,255,255,0.05); border-radius: 8px; }
        .step-title { color: #f093fb; font-weight: bold; margin-bottom: 10px; }
        .qr-section { text-align: center; padding: 20px; }
        .qr-section img { border: 2px solid #f093fb; border-radius: 10px; }
        .stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin: 20px 0; }
        .stat { text-align: center; padding: 15px; background: rgba(255,255,255,0.05); border-radius: 12px; }
        .stat-value { font-size: 1.5rem; color: #f093fb; }
        .loading { display: none; text-align: center; padding: 30px; }
        .loading.show { display: block; }
        .spinner { width: 40px; height: 40px; border: 4px solid rgba(255,255,255,0.1); border-top-color: #f093fb; border-radius: 50%%; animation: spin 1s linear infinite; margin: 0 auto 15px; }
        @keyframes spin { to { transform: rotate(360deg); } }
        @media (max-width: 600px) { .stats { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🤖 LLM Ordusu</h1>
            <div class="badge">⚡ Go API Server</div>
        </header>

        <div class="card">
            <h2>🧠 Zeki Düşünce Motoru</h2>
            <div class="input-group">
                <input type="text" id="question" placeholder="Sorunuzu yazın...">
                <button onclick="askQuestion()">Düşün</button>
            </div>
            <div class="loading" id="loading">
                <div class="spinner"></div>
                <p>AI Chain of Thought ile düşünüyor...</p>
            </div>
            <div id="result"></div>
        </div>

        <div class="card">
            <h2>📊 Sistem Durumu</h2>
            <div class="stats">
                <div class="stat">
                    <div class="stat-value" id="model">-</div>
                    <div>Model</div>
                </div>
                <div class="stat">
                    <div class="stat-value" id="status">-</div>
                    <div>Durum</div>
                </div>
                <div class="stat">
                    <div class="stat-value" id="latency">-</div>
                    <div>Son Latency</div>
                </div>
            </div>
        </div>

        <div class="card">
            <h2>📱 Mobil Erişim</h2>
            <div class="qr-section">
                <img src="%s" alt="QR Code">
                <p style="margin-top: 15px;">http://%s:%s</p>
            </div>
        </div>
    </div>

    <script>
        async function askQuestion() {
            const q = document.getElementById('question').value;
            if (!q) return;

            document.getElementById('loading').classList.add('show');
            document.getElementById('result').innerHTML = '';

            try {
                const res = await fetch('/api/think?q=' + encodeURIComponent(q));
                const data = await res.json();

                let html = '';
                if (data.steps) {
                    data.steps.forEach(s => {
                        html += '<div class="step"><div class="step-title">Adım ' + s.step + ': ' + s.title + '</div>' + s.content + '</div>';
                    });
                    html += '<div class="result"><strong>Final:</strong> ' + data.final_answer + '</div>';
                    document.getElementById('latency').textContent = data.thinking_ms + 'ms';
                }
                document.getElementById('result').innerHTML = html;
            } catch (e) {
                document.getElementById('result').innerHTML = '<div class="result">Hata: ' + e.message + '</div>';
            }

            document.getElementById('loading').classList.remove('show');
        }

        async function checkStatus() {
            try {
                const res = await fetch('/api/status');
                const data = await res.json();
                document.getElementById('model').textContent = data.model.split(':')[0];
                document.getElementById('status').textContent = data.status === 'online' ? '✅' : '❌';
            } catch (e) {
                document.getElementById('status').textContent = '❌';
            }
        }

        checkStatus();
        document.getElementById('question').addEventListener('keypress', e => { if (e.key === 'Enter') askQuestion(); });
    </script>
</body>
</html>`, qrURL, serverIP, ServerPort)
}

// ============================================
// HTTP HANDLER'LAR
// ============================================

func handleIndex(w http.ResponseWriter, r *http.Request) {
	localIP := getLocalIP()
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprint(w, getMainHTML(localIP))
}

func handleThink(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	question := r.URL.Query().Get("q")
	if question == "" {
		json.NewEncoder(w).Encode(map[string]string{"error": "Soru gerekli"})
		return
	}

	result := chainOfThought(question)
	json.NewEncoder(w).Encode(result)
}

func handleStatus(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	status := StatusResponse{
		Status:    "online",
		Model:     DefaultModel,
		Timestamp: time.Now().Format(time.RFC3339),
		GoVersion: "1.21+",
	}

	json.NewEncoder(w).Encode(status)
}

func handleChat(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	prompt := r.URL.Query().Get("prompt")
	if prompt == "" {
		json.NewEncoder(w).Encode(map[string]string{"error": "Prompt gerekli"})
		return
	}

	response, err := callOllama(prompt, DefaultModel)
	if err != nil {
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	json.NewEncoder(w).Encode(map[string]string{"response": response})
}

// ============================================
// ANA FONKSİYON
// ============================================

func main() {
	localIP := getLocalIP()

	fmt.Println(`
╔═══════════════════════════════════════════════════════════╗
║  LLM ORDUSU - GO API SERVER                               ║
║  High Performance + Düşünce Motoru                        ║
╚═══════════════════════════════════════════════════════════╝`)

	fmt.Printf("\n🚀 Go API Server başlatılıyor...\n\n")
	fmt.Printf("📱 MOBİL ERİŞİM:\n")
	fmt.Printf("   Yerel:  http://localhost:%s\n", ServerPort)
	fmt.Printf("   Ağ:     http://%s:%s\n\n", localIP, ServerPort)
	fmt.Printf("📲 QR Kod: %s\n\n", generateQRURL(fmt.Sprintf("http://%s:%s", localIP, ServerPort)))
	fmt.Printf("⏹️  Durdurmak için Ctrl+C\n\n")

	// Route'ları tanımla
	http.HandleFunc("/", handleIndex)
	http.HandleFunc("/api/think", handleThink)
	http.HandleFunc("/api/status", handleStatus)
	http.HandleFunc("/api/chat", handleChat)

	// Sunucuyu başlat
	err := http.ListenAndServe(":"+ServerPort, nil)
	if err != nil {
		fmt.Printf("❌ Sunucu başlatılamadı: %v\n", err)
	}
}
