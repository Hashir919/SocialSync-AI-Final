"""
tflite_inference.py — SocialSync AI Model Inference Engine
Primary model: final_reply_modelv3 (T5ForConditionalGeneration)
"""

import os
import re
import torch

_generator = None   # lazy singleton


# ─── Prompt wrapping ──────────────────────────────────────────────────────────

def _wrap_prompt(instruction: str) -> str:
    """Wrap instruction in the LaMini-Flan-T5 training format for best output."""
    return (
        "Below is an instruction that describes a task. "
        "Write a response that appropriately completes the request.\n\n"
        f"### Instruction:\n{instruction}\n\n"
        "### Response:"
    )


# ─── Identity guard ───────────────────────────────────────────────────────────

_BANNED_PHRASES = [
    "google ai", "gemini", "chatgpt", "gpt", "openai", "claude", "anthropic",
    "llama", "hugging face", "huggingface", "i am an ai language model",
    "as an ai language model", "as a large language model", "as a google",
    "i'm powered by", "i am powered by",
]

_IDENTITY_TRIGGERS = [
    "who are you", "what are you", "what ai", "which ai", "are you gemini",
    "are you chatgpt", "are you gpt", "are you google", "your name",
    "what's your name", "what is your name",
]

_IDENTITY_RESPONSE = (
    "I'm SocialSync AI, your personal communication coach. "
    "I'm here to help you improve conversations, build confidence, "
    "prepare for interviews, navigate social interactions, and develop your communication skills."
)


def _is_identity_question(text: str) -> bool:
    t = text.lower().strip()
    return any(phrase in t for phrase in _IDENTITY_TRIGGERS)


def _sanitize(text: str) -> str:
    """Remove any mention of external AI providers from model output."""
    lower = text.lower()
    for phrase in _BANNED_PHRASES:
        if phrase in lower:
            # Replace the whole sentence containing the banned phrase
            sentences = re.split(r'(?<=[.!?])\s+', text)
            text = " ".join(
                s for s in sentences
                if not any(p in s.lower() for p in _BANNED_PHRASES)
            ).strip()
            break
    return text.strip()


# ─── Generator class ──────────────────────────────────────────────────────────

class SocialSyncGenerator:
    """
    Wraps final_reply_modelv3 (T5ForConditionalGeneration) for inference.
    Falls back to final_reply_modelv2 if v3 is not available.
    """

    def __init__(self):
        from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

        models_dir = os.path.abspath(
            os.path.join(os.path.dirname(__file__), "..", "..", "ai_models")
        )
        v3 = os.path.join(models_dir, "final_reply_modelv3")
        v2 = os.path.join(models_dir, "final_reply_modelv2")

        for path, label in [(v3, "final_reply_modelv3"), (v2, "final_reply_modelv2")]:
            try:
                print(f"[SocialSync AI] Loading {label} …")
                self.tokenizer = AutoTokenizer.from_pretrained(path, local_files_only=True)
                self.model = AutoModelForSeq2SeqLM.from_pretrained(path, local_files_only=True)
                self.model.eval()
                print(f"[SocialSync AI] {label} loaded successfully.")
                self._model_label = label
                return
            except Exception as e:
                print(f"[SocialSync AI] {label} failed: {e}")

        raise RuntimeError("No model could be loaded. Check ai_models/ directory.")

    def generate(self, instruction: str, temperature: float = 0.7) -> str:
        prompt = _wrap_prompt(instruction)
        inputs = self.tokenizer(
            prompt,
            return_tensors="pt",
            truncation=True,
            max_length=512,
        )
        with torch.no_grad():
            use_sampling = temperature > 0.0
            kwargs = {
                "max_new_tokens": 150,
                "do_sample": use_sampling,
                "repetition_penalty": 1.3,
                "no_repeat_ngram_size": 3,
            }
            if use_sampling:
                kwargs["temperature"] = max(temperature, 0.65)
                kwargs["top_p"] = 0.92
                kwargs["top_k"] = 50
                kwargs["num_beams"] = 1
            else:
                kwargs["num_beams"] = 4

            outputs = self.model.generate(**inputs, **kwargs)

        raw = self.tokenizer.decode(outputs[0], skip_special_tokens=True).strip()

        # Clean up echoed prompt fragments
        if "### Response:" in raw:
            raw = raw.split("### Response:")[-1].strip()
        raw = re.sub(
            r"^(Response|Coach|Assistant|SocialSync AI):\s*",
            "", raw, flags=re.IGNORECASE,
        ).strip()

        return raw


# ─── Public API ───────────────────────────────────────────────────────────────

def generate_tflite_reply(instruction: str, temperature: float = 0.7) -> str:
    """
    Primary inference entry point used by model_pipeline.py.
    - Intercepts identity questions before hitting the model.
    - Sanitizes output to remove any mention of external AI providers.
    - Returns empty string on failure so model_pipeline can use coaching_engine fallback.
    """
    # Handle identity questions without calling the model
    if _is_identity_question(instruction):
        return _IDENTITY_RESPONSE

    global _generator
    if _generator is None:
        try:
            _generator = SocialSyncGenerator()
        except Exception as e:
            print(f"[SocialSync AI] Model init failed: {e}")
            return ""

    try:
        reply = _generator.generate(instruction, temperature=temperature)
        reply = _sanitize(reply)
        return reply
    except Exception as e:
        print(f"[SocialSync AI] Inference error: {e}")
        return ""
