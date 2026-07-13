"""
main.py - SocialSync AI Backend (Production)
FastAPI entry point.

Directory layout (relative to this file):
  backend/
    main.py          ← this file
    scripts/
      model_pipeline.py
      tflite_inference.py
    coaching_dataset.json
    socialsync_dataset.json

  ai_models/           ← one level up
    emotion_classifier.pkl
    rewrite_matcher.pkl
    ...
"""

import os
import sys
import json
import logging
import asyncio
import random
from pathlib import Path

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# ─── Environment ──────────────────────────────────────────────────────────────
load_dotenv()

# ─── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("socialsync")

# ─── Path resolution ──────────────────────────────────────────────────────────
# backend/ is this file's directory; repo root is its parent
BACKEND_DIR = Path(__file__).resolve().parent
REPO_ROOT = BACKEND_DIR.parent

# Add backend/ to sys.path so `from scripts.model_pipeline import ...` works
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

# ─── AI pipeline imports ──────────────────────────────────────────────────────
try:
    from scripts.model_pipeline import (
        analyze_emotion_hf,
        rewrite_message_hf,
        generate_coach_response_hf,
        calculate_ai_metrics,
        get_live_coaching_tips,
        route_user_input,
    )
    logger.info("AI pipeline loaded successfully.")
except Exception as exc:
    logger.critical("Failed to import AI pipeline: %s", exc, exc_info=True)
    raise

# ─── Coaching dataset (optional enrichment) ───────────────────────────────────
_coaching_dataset_path = BACKEND_DIR / "coaching_dataset.json"
coaching_dataset: list = []
if _coaching_dataset_path.is_file():
    try:
        with open(_coaching_dataset_path, "r", encoding="utf-8") as _f:
            coaching_dataset = json.load(_f)
        logger.info("Loaded %d coaching examples.", len(coaching_dataset))
    except Exception as exc:
        logger.warning("Could not load coaching dataset: %s", exc)

# ─── FastAPI application ──────────────────────────────────────────────────────
app = FastAPI(
    title="SocialSync AI API",
    version="1.0.0",
    description="AI-powered social communication coaching backend.",
)

# ─── CORS ─────────────────────────────────────────────────────────────────────
_cors_origins_raw = os.getenv("CORS_ORIGINS", "*")
allowed_origins = [o.strip() for o in _cors_origins_raw.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ══════════════════════════════════════════════════════════════════════════════
# REST ENDPOINTS
# ══════════════════════════════════════════════════════════════════════════════

@app.get("/", tags=["Health"])
async def read_root():
    return {"status": "SocialSync AI Backend is running", "version": "1.0.0"}


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok"}


@app.post("/emotion", tags=["AI"])
async def emotion_endpoint(payload: dict):
    """Detect emotion in text. Returns emotion label and anxiety score."""
    text = payload.get("text", "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="'text' field is required.")
    try:
        return analyze_emotion_hf(text)
    except Exception as exc:
        logger.error("Emotion detection error: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail="Emotion detection failed.")


@app.post("/rewrite", tags=["AI"])
async def rewrite_endpoint(payload: dict):
    """Rewrite a message with the desired tone and context."""
    text = payload.get("text", "").strip()
    tone = payload.get("tone", "Confident")
    context = payload.get("context", "General")
    if not text:
        raise HTTPException(status_code=400, detail="'text' field is required.")
    try:
        improved, suggestion = rewrite_message_hf(text, context=context, tone=tone)
        return {"improved": improved, "suggestion": suggestion}
    except Exception as exc:
        logger.error("Rewrite error: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail="Rewrite failed.")


@app.post("/generate", tags=["AI"])
async def generate_endpoint(payload: dict):
    """Generate an AI coach reply for a given prompt."""
    prompt = payload.get("prompt", "").strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="'prompt' field is required.")
    try:
        reply = generate_coach_response_hf(prompt, "AI Coach", "General")
        return {"reply": reply}
    except Exception as exc:
        logger.error("Generate error: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail="Generation failed.")


@app.post("/tone", tags=["AI"])
async def tone_endpoint(payload: dict):
    """Analyse communication metrics (confidence, clarity, empathy, etc.)."""
    text = payload.get("text", "").strip()
    context = payload.get("context", "General")
    mode = payload.get("mode", "chat")
    if not text:
        raise HTTPException(status_code=400, detail="'text' field is required.")
    try:
        return calculate_ai_metrics(text, context, mode)
    except Exception as exc:
        logger.error("Tone analysis error: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail="Tone analysis failed.")


@app.post("/conversation", tags=["AI"])
async def conversation_endpoint(payload: dict):
    """Route user input to the most relevant coaching task."""
    text = payload.get("text", "").strip()
    context = payload.get("context", "General")
    persona = payload.get("persona", "")
    if not text:
        raise HTTPException(status_code=400, detail="'text' field is required.")
    try:
        task, confidence = route_user_input(text, context=context, persona=persona)
        return {"task": task, "confidence": confidence}
    except Exception as exc:
        logger.error("Conversation routing error: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail="Routing failed.")


# ══════════════════════════════════════════════════════════════════════════════
# WEBSOCKET ENDPOINT
# ══════════════════════════════════════════════════════════════════════════════

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """Real-time coaching WebSocket session."""
    await websocket.accept()
    session_id = f"session_{id(websocket)}"
    logger.info("WebSocket connected: %s", session_id)
    try:
        while True:
            raw_data = await websocket.receive_text()
            await asyncio.sleep(random.uniform(0.3, 0.6))
            try:
                data = json.loads(raw_data)
                text = data.get("text", "").strip()
                context = data.get("context", "Friendship")
                mode = data.get("mode", "chat")
                persona = data.get("persona", "")
                tone = data.get("tone", "Confident")
            except (json.JSONDecodeError, AttributeError):
                text = raw_data.strip()
                context, mode, persona, tone = "Friendship", "chat", "", "Confident"

            if not text:
                continue

            is_ai_coach = "ai coach" in persona.lower() or persona.lower() == "coach"
            try:
                metrics = calculate_ai_metrics(text, context, mode)
                if is_ai_coach:
                    persona_reply = generate_coach_response_hf(text, "AI Coach", context, session_id=session_id)
                    response = {
                        "transcript": text, "context": context, "mode": mode,
                        "emotion": metrics["anxiety"],
                        "anxiety": f"{metrics['anxiety']}%", "confidence": f"{metrics['confidence']}%",
                        "clarity": f"{metrics['clarity']}%", "friendliness": f"{metrics['friendliness']}%",
                        "professionalism": f"{metrics['professionalism']}%", "empathy": f"{metrics['empathy']}%",
                        "pace": "N/A", "persona_reply": persona_reply,
                    }
                else:
                    improved, suggestion = rewrite_message_hf(text, context=context, tone=tone)
                    coaching_tips = get_live_coaching_tips(
                        metrics["anxiety"], metrics["confidence"], metrics["clarity"], metrics["pace"], context
                    )
                    persona_reply = generate_coach_response_hf(text, persona, context, session_id=session_id) if persona else ""
                    emotion_result = analyze_emotion_hf(text)
                    response = {
                        "transcript": text, "context": context, "mode": mode,
                        "emotion": emotion_result.get("emotion", "Neutral"),
                        "anxiety": f"{metrics['anxiety']}%", "confidence": f"{metrics['confidence']}%",
                        "clarity": f"{metrics['clarity']}%", "friendliness": f"{metrics['friendliness']}%",
                        "professionalism": f"{metrics['professionalism']}%", "empathy": f"{metrics['empathy']}%",
                        "pace": f"{metrics['pace']} wpm" if mode == "voice" else "N/A",
                        "suggestion": suggestion, "improved": improved,
                        "coaching_tips": coaching_tips, "persona_reply": persona_reply,
                    }
                await websocket.send_json(response)
            except Exception as exc:
                logger.error("WS processing error [%s]: %s", session_id, exc, exc_info=True)
                await websocket.send_json({"error": "Processing failed. Please try again."})

    except WebSocketDisconnect:
        logger.info("WebSocket disconnected: %s", session_id)
    except Exception as exc:
        logger.error("WebSocket fatal error [%s]: %s", session_id, exc, exc_info=True)


# ══════════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8000"))
    logger.info("Starting SocialSync AI server on port %d", port)
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")
