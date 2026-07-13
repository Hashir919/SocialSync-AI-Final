import os
import torch
import re
from transformers import T5TokenizerFast, T5ForConditionalGeneration

# Global cache for the reply generator using the HuggingFace LaMini-Flan-T5-77M model
_reply_generator = None

# Generation parameters (can be tuned per use)
MAX_LENGTH = 64
REPEAT_PENALTY = 1.3
TEMPERATURE = 0.0
TOP_P = 0.95
TOP_K = 50

def clean_response(text: str) -> str:
    """Removes common filler phrases or incomplete patterns from the model output."""
    text = re.sub(r"Please try again later\.", "", text, flags=re.IGNORECASE)
    # Remove metadata prefixes
    text = re.sub(r"^(Response|Coach response|Interviewer response|Partner response|Assistant|Coach):\s*", "", text, flags=re.IGNORECASE)
    return text.strip()

class PyTorchReplyGenerator:
    """Encapsulates loading and inference for the T5 model using PyTorch.
    The class caches the tokenizer and model, and provides a generate method
    with sensible defaults to reduce repetition and improve response quality.
    """
    def __init__(self, model_name: str = "MBZUAI/LaMini-Flan-T5-77M"):
        # Resolve the paths to local directories
        models_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "ai_models"))
        v2_dir = os.path.join(models_dir, "final_reply_modelv2")
        fallback_dir = os.path.join(models_dir, "final_reply_model")

        from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
        
        try:
            print(f"[PyTorch Generator] Loading local HuggingFace model from {v2_dir} …")
            self.tokenizer = AutoTokenizer.from_pretrained(v2_dir, local_files_only=True)
            self.model = AutoModelForSeq2SeqLM.from_pretrained(v2_dir, local_files_only=True)
        except Exception as e:
            print(f"[PyTorch Generator] Failed loading from {v2_dir}: {e}. Trying fallback from {fallback_dir}…")
            self.tokenizer = AutoTokenizer.from_pretrained(fallback_dir, local_files_only=True)
            self.model = AutoModelForSeq2SeqLM.from_pretrained(fallback_dir, local_files_only=True)

        # Ensure the model is in evaluation mode for inference
        self.model.eval()
        print("[PyTorch Generator] Model and tokenizer loaded successfully.")

    def generate(
        self,
        prompt: str,
        max_length: int = 64,
        repetition_penalty: float = 1.3,
        temperature: float = 0.0,
        no_repeat_ngram_size: int = 3,
    ) -> str:
        """Generate a response for *prompt*.

        Parameters
        ----------
        prompt: str
            The input text to generate a reply for.
        max_length: int, default 64
            Maximum token length of the generated reply.
        repetition_penalty: float, default 1.3
            Penalises repeated tokens.
        temperature: float, default 0.0
            Controls randomness; 0.0 yields deterministic output.
        no_repeat_ngram_size: int, default 3
            Prevents the model from repeating n‑grams of this size.
        """
        inputs = self.tokenizer(prompt, return_tensors="pt")
        with torch.no_grad():
            generation_kwargs = {
    "max_new_tokens": 80,
    "do_sample": False,
    "num_beams": 4,
    "early_stopping": True,
    "repetition_penalty": 1.2,
    "no_repeat_ngram_size": 3,
}
            outputs = self.model.generate(**inputs, **generation_kwargs)
        # Decode and clean up output
        return self.tokenizer.decode(outputs[0], skip_special_tokens=True).strip()

def generate_tflite_reply(prompt: str, temperature: float = 0.0) -> str:
    """Primary reply engine for the application.

    This function lazily initialises a global :class:`PyTorchReplyGenerator`
    instance on first call and re‑uses it for subsequent requests, avoiding
    the costly model reload cost.
    """
    global _reply_generator
    if _reply_generator is None:
        try:
            _reply_generator = PyTorchReplyGenerator()
        except Exception as e:
            print(f"[PyTorch Generator] Failed to initialise HuggingFace model: {e}")
            raise
    try:
        response = _reply_generator.generate(prompt, temperature=temperature)
        return clean_response(response)
    except Exception as e:
        print(f"[PyTorch Generator] Inference error: {e}")
        return "I couldn't generate a response right now. Please try again later."
