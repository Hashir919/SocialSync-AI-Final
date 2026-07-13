# SocialSync AI

> **AI-powered real-time communication coaching platform.**
> Emotion detection · Message rewriting · Confidence scoring · Live coaching · WebSocket sessions

---

## 🏗 Architecture

```
SocialSync-AI-Final/
├── frontend/              Flutter mobile app (Android / iOS)
├── backend/               FastAPI AI backend
│   ├── main.py            REST + WebSocket server
│   ├── scripts/           AI inference pipeline
│   │   ├── model_pipeline.py
│   │   └── tflite_inference.py
│   ├── coaching_dataset.json
│   ├── socialsync_dataset.json
│   ├── requirements.txt
│   ├── runtime.txt
│   └── .env.example
├── ai_models/             Runtime model artifacts
│   ├── emotion_classifier.pkl
│   ├── rewrite_matcher.pkl
│   ├── conversational_retriever.pkl
│   ├── intent_classifier.pkl
│   └── final_reply_modelv2/   (tokenizer + config; weights downloaded separately)
├── docs/                  Architecture & setup guides
├── scripts/               Utility scripts
├── render.yaml            Render deployment config
├── .gitignore
├── LICENSE
└── README.md
```

---

## ⚡ Prerequisites

| Tool | Version |
|---|---|
| Flutter SDK | ≥ 3.0 |
| Dart | ≥ 3.0 |
| Python | 3.11.6 |
| pip | ≥ 23 |
| Android Studio | Latest (for Android) |

---

## 🐍 Backend — Local Setup

### 1. Create a virtual environment
```bash
cd backend
python -m venv .venv

# Windows
.venv\Scripts\activate
# macOS / Linux
source .venv/bin/activate
```

### 2. Install dependencies
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Configure environment
```bash
cp .env.example .env
# Edit backend/.env — set CORS_ORIGINS to your device IP for local testing
```

### 4. Download AI model weights
Large weight binaries are not stored in this repo (GitHub 100 MB limit). Download once:

```bash
pip install huggingface_hub
python -c "
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='MBZUAI/LaMini-Flan-T5-77M',
    local_dir='../ai_models/final_reply_modelv2',
    ignore_patterns=['*.msgpack', '*.h5'],
)
print('Done.')
"
```

### 5. Start the server
```bash
# Run from the backend/ directory
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

- API root: `http://localhost:8000`
- Interactive docs: `http://localhost:8000/docs`

---

## 📱 Flutter Frontend — Local Setup

### 1. Install packages
```bash
cd frontend
flutter pub get
```

### 2. Run on device / emulator
```bash
# Point to your local backend
flutter run --dart-define=BACKEND_URL=ws://YOUR_LOCAL_IP:8000/ws
```

> **Tips:**
> - Find your local IP: `ipconfig` (Windows) · `ifconfig` (macOS/Linux)
> - Android Emulator → use `ws://10.0.2.2:8000/ws`
> - Physical device → use your machine's LAN IP e.g. `ws://192.168.1.5:8000/ws`

### 3. Run without a backend (simulation fallback)
```bash
flutter run
# The app falls back to client-side simulation when the backend is unreachable
```

---

## 🔑 Environment Variables

### Backend (`backend/.env`)
| Variable | Default | Description |
|---|---|---|
| `PORT` | `8000` | Server port (Render sets this automatically) |
| `CORS_ORIGINS` | `*` | Comma-separated allowed CORS origins |

### Flutter (`--dart-define`)
| Variable | Default | Description |
|---|---|---|
| `BACKEND_URL` | `ws://127.0.0.1:8000/ws` | WebSocket backend URL |

---

## 📡 API Reference

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | Server status |
| `GET` | `/health` | Health check (Render probe) |
| `POST` | `/emotion` | Detect emotion in text |
| `POST` | `/rewrite` | Rewrite message with tone adjustment |
| `POST` | `/generate` | Generate AI coach reply |
| `POST` | `/tone` | Analyse communication metrics |
| `POST` | `/conversation` | Route input to coaching task |
| `WS` | `/ws` | Real-time coaching session |

### Example — Emotion Detection
```bash
curl -X POST http://localhost:8000/emotion \
  -H "Content-Type: application/json" \
  -d '{"text": "I am so nervous about my interview"}'
# {"emotion": "Fear", "anxiety_score": 0.85}
```

### Example — Message Rewrite
```bash
curl -X POST http://localhost:8000/rewrite \
  -H "Content-Type: application/json" \
  -d '{"text": "um maybe i could try", "tone": "Confident", "context": "Interview"}'
# {"improved": "Absolutely! I can ...", "suggestion": "..."}
```

### WebSocket Payload Format
```json
{
  "text": "Your message here",
  "context": "Interview",
  "mode": "chat",
  "persona": "Interview Coach",
  "tone": "Confident"
}
```

---

## 🤖 AI Models

All inference runs **locally** — no external API calls required.

| Model | File | Purpose |
|---|---|---|
| LaMini-Flan-T5-77M (fine-tuned) | `ai_models/final_reply_modelv2/` | Reply generation & rewriting |
| Emotion Classifier | `ai_models/emotion_classifier.pkl` | Fast emotion detection |
| Rewrite Matcher | `ai_models/rewrite_matcher.pkl` | Similarity-based rewrite lookup |
| Conversational Retriever | `ai_models/conversational_retriever.pkl` | Dialogue history |
| Intent Classifier | `ai_models/intent_classifier.pkl` | Task routing |

**Fallback chain:** Local sklearn model → DistilBERT (HuggingFace) → Keyword heuristics

---

## 🏗 Build Android APK

```bash
cd frontend

# Debug build
flutter build apk --debug

# Release build (requires signing config in android/key.properties)
flutter build apk --release \
  --dart-define=BACKEND_URL=wss://your-app.onrender.com/ws

# Output:
# frontend/build/app/outputs/flutter-apk/app-release.apk
```

---

## ☁️ Deploy Backend to Render

1. Push this repo to GitHub
2. [render.com](https://render.com) → **New Web Service** → connect the repo
3. Render auto-detects `render.yaml` (`rootDir: backend`)
4. Set env var: `CORS_ORIGINS` = your Flutter app's URL
5. After first deploy, open the Render shell and download model weights:
   ```bash
   pip install huggingface_hub
   python -c "
   from huggingface_hub import snapshot_download
   snapshot_download('MBZUAI/LaMini-Flan-T5-77M',
     local_dir='../ai_models/final_reply_modelv2',
     ignore_patterns=['*.msgpack','*.h5'])
   "
   ```

> **Recommended plan:** Standard ($7/month) — needs ≥ 1 GB RAM for AI models.

---

## 🔗 Connecting Flutter to the Deployed Backend

Update the default value in `frontend/lib/services/websocket_service.dart`:
```dart
const backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'wss://your-app.onrender.com/ws',  // ← change this
);
```

Or pass it at build time:
```bash
flutter build apk --release \
  --dart-define=BACKEND_URL=wss://your-app.onrender.com/ws
```

---

## 🛠 Troubleshooting

| Problem | Solution |
|---|---|
| `torch` install fails on Render | Ensure `--extra-index-url https://download.pytorch.org/whl/cpu` is the first line of `requirements.txt` |
| Flutter can't connect to backend | Check `BACKEND_URL`; use `10.0.2.2` for emulator, LAN IP for physical device |
| `emotion_classifier.pkl` not found | Verify `ai_models/` is at the repo root (one level above `backend/`) |
| AI replies are generic / short | Model weights not downloaded — run the `huggingface_hub` download command |
| Supabase auth fails | Update `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `frontend/lib/main.dart` |
| Flutter build error | Run `flutter clean && flutter pub get` then retry |
| `Import "scripts.model_pipeline" not found` | Run uvicorn from the `backend/` directory, not from the repo root |

---

## 📄 License

MIT — see [LICENSE](LICENSE)
