# SocialSync AI

> **AI-powered real-time communication coaching platform.**
> Emotion detection · Message rewriting · Confidence scoring · Live coaching · WebSocket sessions

---

## 🚀 How to Run the Project

Follow these steps **in order**. Do this once after cloning the repository.

### Step 1 — Clone the repository

```bash
git clone https://github.com/Hashir919/SocialSync-AI-Final.git
cd SocialSync-AI-Final
```

---

### Step 2 — Run the Backend

#### 2a. Create a Python virtual environment

```bash
cd backend
python -m venv .venv
```

Activate it:

```bash
# Windows
.venv\Scripts\activate

# macOS / Linux
source .venv/bin/activate
```

#### 2b. Install dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

> ⏳ This takes a few minutes — it downloads PyTorch (CPU), transformers, and scikit-learn.

#### 2c. Download AI model weights (one-time setup)

The large model weights are not stored in the repo. Download them:

```bash
pip install huggingface_hub
python -c "
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='MBZUAI/LaMini-Flan-T5-77M',
    local_dir='../ai_models/final_reply_modelv2',
    ignore_patterns=['*.msgpack', '*.h5'],
)
print('Model weights ready.')
"
```

> ⬇️ This downloads ~310 MB. Only needed once.

#### 2d. Set up environment variables

```bash
cp .env.example .env
```

The defaults work for local development. No changes needed.

#### 2e. Start the backend server

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

✅ You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

Test it in your browser: **http://localhost:8000/health** → should return `{"status":"ok"}`

---

### Step 3 — Run the Flutter Frontend

> Open a **new terminal** (keep the backend running).

#### 3a. Install Flutter packages

```bash
cd frontend
flutter pub get
```

#### 3b. Find your machine's local IP address

```bash
# Windows
ipconfig
# Look for "IPv4 Address" e.g. 192.168.1.5

# macOS / Linux
ifconfig | grep "inet "
```

#### 3c. Run the app

```bash
# Android emulator (use 10.0.2.2 to reach your machine)
flutter run --dart-define=BACKEND_URL=ws://10.0.2.2:8000/ws

# Physical Android/iOS device (use your actual IP)
flutter run --dart-define=BACKEND_URL=ws://192.168.1.5:8000/ws

# Run without backend (uses local simulation fallback)
flutter run
```

✅ The app will launch on your connected device or emulator.

---

### Step 4 — Verify Everything Works

| Check | How |
|---|---|
| Backend running | Visit `http://localhost:8000/docs` — you should see the API docs |
| Emotion endpoint | `POST /emotion` with `{"text": "I am nervous"}` |
| Frontend connected | Green connection indicator in the app's home screen |
| AI coaching working | Start a practice session and speak or type a message |

---

## 📁 Project Structure

```
SocialSync-AI-Final/
├── frontend/              Flutter mobile app (Android / iOS)
├── backend/               FastAPI AI backend
│   ├── main.py            REST + WebSocket server
│   ├── scripts/           AI inference pipeline
│   │   ├── model_pipeline.py
│   │   └── tflite_inference.py
│   ├── coaching_dataset.json
│   ├── requirements.txt
│   ├── runtime.txt
│   └── .env.example
├── ai_models/             Runtime model artifacts
│   ├── emotion_classifier.pkl
│   ├── rewrite_matcher.pkl
│   ├── conversational_retriever.pkl
│   ├── intent_classifier.pkl
│   └── final_reply_modelv2/   (tokenizer + config; weights downloaded in Step 2c)
├── docs/
├── render.yaml            Render deployment config
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🏗 Architecture

```
Flutter App
    │  WebSocket (ws://localhost:8000/ws)
    │  REST (http://localhost:8000)
    ▼
FastAPI Backend  (backend/main.py)
    │
    ├── /emotion     → emotion_classifier.pkl  (sklearn)
    ├── /rewrite     → rewrite_matcher.pkl + LaMini-T5
    ├── /generate    → LaMini-Flan-T5-77M     (local PyTorch)
    ├── /tone        → metric calculation
    ├── /conversation→ intent_classifier.pkl
    └── /ws          → real-time coaching session
```

---

## 🔑 Environment Variables

### Backend (`backend/.env`)
| Variable | Default | Description |
|---|---|---|
| `PORT` | `8000` | Server port |
| `CORS_ORIGINS` | `*` | Allowed origins (set to your device IP for local dev) |

### Flutter (`--dart-define`)
| Variable | Default | Description |
|---|---|---|
| `BACKEND_URL` | `ws://127.0.0.1:8000/ws` | WebSocket backend URL |

---

## 📡 API Endpoints

| Method | Path | Body | Description |
|---|---|---|---|
| `GET` | `/health` | — | Health check |
| `POST` | `/emotion` | `{"text": "..."}` | Detect emotion |
| `POST` | `/rewrite` | `{"text": "...", "tone": "Confident", "context": "Interview"}` | Rewrite message |
| `POST` | `/generate` | `{"prompt": "..."}` | Generate AI reply |
| `POST` | `/tone` | `{"text": "...", "context": "..."}` | Analyse metrics |
| `POST` | `/conversation` | `{"text": "...", "context": "..."}` | Route to coaching task |
| `WS` | `/ws` | JSON payload | Real-time coaching |

Full interactive docs at **http://localhost:8000/docs**

---

## 🤖 AI Models

All inference runs **locally** — no external API calls.

| Model | File | Purpose |
|---|---|---|
| LaMini-Flan-T5-77M | `ai_models/final_reply_modelv2/` | Reply generation & rewriting |
| Emotion Classifier | `ai_models/emotion_classifier.pkl` | Emotion detection |
| Rewrite Matcher | `ai_models/rewrite_matcher.pkl` | Similarity-based rewrites |
| Conversational Retriever | `ai_models/conversational_retriever.pkl` | Dialogue history |
| Intent Classifier | `ai_models/intent_classifier.pkl` | Task routing |

**Fallback chain:** Local sklearn → DistilBERT (HuggingFace) → Keyword heuristics

---

## 🏗 Build Android APK

```bash
cd frontend

# Debug APK
flutter build apk --debug

# Release APK (connected to production backend)
flutter build apk --release \
  --dart-define=BACKEND_URL=wss://your-app.onrender.com/ws

# Output: frontend/build/app/outputs/flutter-apk/app-release.apk
```

---

## ☁️ Deploy Backend to Render

1. Push to GitHub
2. [render.com](https://render.com) → **New Web Service** → connect this repo
3. Render auto-detects `render.yaml` — sets `rootDir: backend`
4. Set env var `CORS_ORIGINS` = your Flutter app domain
5. After deploy, open the Render shell and run the model weight download (Step 2c above)
6. Update `BACKEND_URL` in Flutter to `wss://your-app.onrender.com/ws`

> **Required plan:** Standard ($7/month) — AI models need ≥ 1 GB RAM.

---

## 🛠 Troubleshooting

| Problem | Solution |
|---|---|
| `torch` install fails | Make sure `requirements.txt` has `--extra-index-url https://download.pytorch.org/whl/cpu` as its first line |
| Flutter can't connect to backend | Use `10.0.2.2` for Android emulator; use LAN IP for physical device |
| `emotion_classifier.pkl` not found | Run `uvicorn` from **inside** the `backend/` folder, not from repo root |
| AI replies are too generic | Model weights not downloaded — run Step 2c |
| Supabase auth fails | Check `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `frontend/lib/main.dart` |
| Flutter build error | Run `flutter clean && flutter pub get` then retry |

---

## 📄 License

MIT — see [LICENSE](LICENSE)
