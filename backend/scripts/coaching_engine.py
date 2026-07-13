"""
coaching_engine.py — SocialSync AI Coaching Engine
Provides high-quality, context-aware responses for all coaching modes.
final_reply_modelv3 handles rewriting; this engine handles dialogue.

Identity: Always "SocialSync AI" — never any external AI provider.
"""

import re
import random
from typing import List, Tuple, Optional


# ─── Identity ─────────────────────────────────────────────────────────────────

IDENTITY_RESPONSE = (
    "I'm SocialSync AI, your personal communication coach. "
    "I'm here to help you improve conversations, build confidence, "
    "prepare for interviews, navigate social interactions, and develop "
    "your communication skills."
)

_IDENTITY_TRIGGERS = [
    "who are you", "what are you", "what ai", "which ai", "are you",
    "your name", "what's your name", "what is your name", "who made you",
    "who built you", "who created you",
]

def _is_identity_question(text: str) -> bool:
    t = text.lower().strip()
    return any(tr in t for tr in _IDENTITY_TRIGGERS)


# ─── Intent detection ─────────────────────────────────────────────────────────

def _detect_intent(text: str) -> str:
    t = text.lower().strip()
    t = re.sub(r"[^\w\s]", " ", t)

    if _is_identity_question(t):
        return "identity"
    if any(w in t for w in ["hello", "hi", "hey", "start", "begin", "good morning", "good evening", "greetings", "howdy"]):
        return "greeting"
    if any(w in t for w in ["feedback", "score", "rate", "evaluate", "review", "how did i do", "results", "assess"]):
        return "request_feedback"
    if any(w in t for w in ["stop", "quit", "end", "bye", "goodbye", "done", "finish", "exit", "thanks", "thank you"]):
        return "ending"
    if any(w in t for w in ["nervous", "anxious", "scared", "afraid", "fear", "worried", "stress", "panic", "terrified", "dread"]):
        return "expressing_anxiety"
    if any(w in t for w in ["confident", "sure", "certain", "ready", "prepared", "strong", "good at", "comfortable"]):
        return "expressing_confidence"
    if any(w in t for w in ["fail", "wrong", "mistake", "terrible", "awful", "bad", "didn't work", "not good", "messed up", "bombed"]):
        return "expressing_failure"
    if any(w in t for w in ["great", "amazing", "excellent", "perfect", "awesome", "did it", "succeeded", "nailed", "crushed"]):
        return "expressing_success"
    if any(w in t for w in ["help", "assist", "guide", "coach", "support", "advice", "tip", "suggest", "improve", "better"]):
        return "ask_help"
    if any(w in t for w in ["practice", "try", "attempt", "work on", "drill", "exercise", "rehearse"]):
        return "wanting_practice"
    if any(w in t for w in ["how", "what", "when", "why", "where", "explain", "tell me", "show me", "difference", "meaning"]):
        return "asking_question"
    return "general"


# ─────────────────────────────────────────────────────────────────────────────
# RESPONSE POOLS — All modes
# ─────────────────────────────────────────────────────────────────────────────

_R = {

    # ── INTERVIEW COACH ──────────────────────────────────────────────────────
    "interview": {
        "identity": [IDENTITY_RESPONSE],
        "greeting": [
            "Welcome to your mock interview session! I'm here to help you walk in confident and walk out with an offer. Let's start — what role are you interviewing for?",
            "Great to have you here! Let's get you interview-ready. First things first — tell me the role and company you're preparing for.",
            "Hello! Let's run a focused mock interview. I'll ask questions, give you real-time feedback, and coach you on delivery. What position are you going for?",
        ],
        "ask_help": [
            "Absolutely — let's prepare you thoroughly. The biggest win in interviews comes from clear, specific answers. Tell me: are you more worried about behavioral questions, technical questions, or just nerves?",
            "Of course! The best prep is targeted practice. Tell me what type of interview it is and I'll focus on what matters most.",
            "Happy to help you prepare. Let's start with something that trips most people up — how would you answer 'Tell me about yourself' right now? Give it a shot.",
        ],
        "expressing_anxiety": [
            "Interview anxiety is completely normal — even experienced professionals feel it. Here's the key: preparation kills anxiety. The more you practice, the more your brain treats the interview as familiar territory. What specific part worries you most?",
            "Take a breath — you've got this. Nervousness means you care, which is a good thing. Let's turn that energy into preparation. Tell me: what's the question you're most afraid they'll ask?",
            "That feeling is your brain's way of saying this matters. Let's work through it. Close your eyes for a second and imagine the interview going well. Now — what's one thing you feel genuinely confident about in your background?",
        ],
        "expressing_confidence": [
            "Love the energy! Confidence is your biggest asset going in. Let's make sure your answers match that energy. Hit me with your 60-second 'Tell me about yourself' pitch.",
            "That confidence will come through — interviewers notice it immediately. Let's keep sharpening it. Here's a tough one: describe a time you failed at something significant. What did you learn?",
            "Great mindset. Now let's stress-test it — how would you handle a question you genuinely don't know the answer to?",
        ],
        "asking_question": [
            "Great question. Use the STAR method for behavioral answers: **Situation** (set the scene briefly), **Task** (your specific responsibility), **Action** (what YOU did — not 'we'), **Result** (quantify the outcome). Want to try one?",
            "Good thing to nail down. When they ask 'Why do you want this role?', connect it to three things: your skills, your growth goals, and genuine interest in what the company does. Never say 'the salary.' Want to practice your version?",
            "Here's a tip: when you get a question you need to think about, say 'Great question — let me think through that.' It buys you 5-10 seconds and actually makes you look thoughtful, not unprepared.",
        ],
        "expressing_failure": [
            "That's okay — rough practice is better than bombing the real thing. Walk me through your answer and let's identify what to fix.",
            "Every stumble in practice is one less stumble in the real interview. Tell me exactly what you said and we'll rebuild it together.",
            "Perfect — this is what prep is for. What part felt weakest to you?",
        ],
        "expressing_success": [
            "Excellent answer! That was clear, specific, and compelling. Remember that feeling — that's exactly how you want to sound in the room.",
            "Strong response! You hit the key points naturally. One small polish: add a number or metric to your result if you can. Quantified achievements always land harder.",
            "Really solid! The interviewer would lean in at that answer. Keep that same energy for the follow-ups.",
        ],
        "request_feedback": [
            "Based on our practice: your strongest area is clarity — you explain things well. Work on adding specific metrics to your results, and slow down slightly when making a key point. Pause for emphasis. Overall, you're in good shape.",
            "Good session! Key takeaways: use STAR structure consistently, open with a strong hook in 'tell me about yourself,' and always ask 2-3 thoughtful questions at the end. Keep practicing — you're improving.",
        ],
        "wanting_practice": [
            "Let's do it! I'll give you a real interview question — answer as naturally as you can. Here we go: 'Tell me about a time you had to manage competing priorities. How did you handle it?'",
            "Great attitude. Practice question: 'What's your biggest professional weakness, and what are you actively doing about it?' Take your time.",
            "Let's run it. Question: 'Describe a time you received difficult feedback. How did you respond?'",
        ],
        "ending": [
            "Great session! You've made real progress. Remember: confidence comes from repetition, not perfection. Come back and practice anytime before your interview. You've got this!",
            "Good work today. Keep practicing your STAR answers tonight — even just mentally running through 3-4 scenarios will make a big difference. Best of luck, though with this prep you won't need it!",
        ],
        "general": [
            "Tell me more about that situation. What was YOUR specific contribution to the outcome?",
            "Good point to build on. How would you frame that in 90 seconds without losing the key details?",
            "Interesting. What would you say the measurable impact was? Numbers always make answers memorable.",
            "Let me push back a bit — an interviewer might ask: 'Can you be more specific?' What would you add?",
            "That's a strong foundation. Now add the result: what changed because of what you did?",
            "Good. Now try saying that again, but cut it in half — interviewers want concise, not comprehensive.",
        ],
    },

    # ── DATING COACH ─────────────────────────────────────────────────────────
    "dating": {
        "identity": [IDENTITY_RESPONSE],
        "greeting": [
            "Hey! Great to practice with you. Dating conversations go best when they feel natural, not scripted. Let's get into it — imagine we just matched and I sent you 'Hey!' back. What do you say next?",
            "Hi! Let's practice making first-date conversation feel effortless. Picture this: we're sitting across from each other at a café for the first time. I'll start — what brings you here this evening?",
            "Hey there! I'm your practice partner for today. First dates are really just two people figuring out if they want a second one. Let's make yours count. How do you usually like to open a conversation?",
        ],
        "ask_help": [
            "Of course! The biggest first-date mistake is treating it like a job interview. You want a conversation, not an interrogation. The trick: share something about yourself, then toss it back with a question. Want to try an opener?",
            "Happy to help. First-date conversations thrive on genuine curiosity. Pick a topic you actually care about and explore it together. What kinds of things do you love talking about?",
        ],
        "expressing_anxiety": [
            "First-date nerves are so real — and honestly, they mean you care. Here's something that actually helps: shift your goal from 'impress them' to 'learn something interesting about them.' The pressure drops immediately. What specifically makes you most nervous?",
            "That nervousness? The other person probably feels it too. You're both in the same boat. One tip: ask one genuine question and really listen to the answer. Real listening is magnetic. What do you want to know about the person you're meeting?",
        ],
        "expressing_confidence": [
            "That energy is great! Confidence is genuinely attractive — just make sure it's paired with genuine curiosity. The best first dates feel like a good conversation, not a performance. What's your go-to opening topic?",
        ],
        "asking_question": [
            "Great instinct to ask that! Open-ended questions are your best tool. Instead of 'Do you like travel?' try 'What's the most interesting place you've ever been?' The second version opens up a real story. Want to practice a few?",
            "Good question to focus on. The conversation formula that works: share a little, ask a little. It creates natural back-and-forth without either person feeling interrogated.",
        ],
        "expressing_success": [
            "That was a really natural response! Warm and genuinely curious — that's exactly the vibe that makes a first date memorable.",
            "Nice! That response shows real interest without coming on too strong. That balance is hard to get right and you nailed it.",
        ],
        "expressing_failure": [
            "Okay, let's work on that. It came across a little flat — what were you trying to convey? We'll find a warmer, more natural way to say the same thing.",
            "That felt a bit forced. The best conversational moments are the ones that feel unplanned. What's a topic you genuinely love? Start there.",
        ],
        "request_feedback": [
            "You've got great natural warmth in your conversation style. The thing to work on: follow-up questions. When someone shares something, dig one level deeper instead of moving to the next topic. You're in great shape though!",
        ],
        "general": [
            "I love that! What got you into it?",
            "Ha, I can tell you're passionate about that. How long have you been into it?",
            "That's such a fun story. What was the best part of that experience?",
            "Okay, I have to ask — what's the most spontaneous thing you've ever done?",
            "That's really interesting. Would you ever do it again?",
            "You seem like you have great taste. What's your go-to recommendation — movie, book, restaurant, anything.",
        ],
    },

    # ── NETWORKING COACH ─────────────────────────────────────────────────────
    "networking": {
        "identity": [IDENTITY_RESPONSE],
        "greeting": [
            "Welcome! Let's practice professional networking — the skill that opens more doors than almost anything else. Picture this: a tech conference, you spot someone interesting at the coffee station. Go ahead — walk up and introduce yourself.",
            "Hi! Networking done right is just genuine relationship-building. Let's practice your elevator pitch. What do you do and what are you looking to connect around?",
        ],
        "ask_help": [
            "Great that you're focusing on this. The key to networking is a memorable, authentic intro. Try this formula: who you are + what you do + one interesting thing about your current work. What does yours look like?",
            "Of course! The biggest networking mistake is making it about yourself. Lead with curiosity. Open with a question about them, not a speech about you. Want to practice a cold introduction?",
        ],
        "expressing_anxiety": [
            "Networking anxiety is super common. Here's a reframe that helps: your job isn't to impress anyone — it's to find the two or three people in the room you could genuinely help or learn from. What's one thing about your work you're actually excited to talk about right now?",
        ],
        "asking_question": [
            "Good approach! Questions that open great networking conversations: 'What are you working on right now that you're most excited about?' or 'What's the biggest challenge in your space right now?' Both invite a real answer, not a one-word response.",
        ],
        "general": [
            "Interesting! What's the most exciting thing you're working on right now?",
            "That's a growing space. How did you find your way into it?",
            "Smart approach. What's been your biggest insight this year working on that?",
            "I'd love to stay in touch — are you on LinkedIn?",
            "That's a real problem a lot of people in the space are hitting. What's your angle on solving it?",
            "Impressive. What does the next year look like for you in that direction?",
        ],
    },

    # ── SOCIAL / FRIENDSHIP COACH ────────────────────────────────────────────
    "friendship": {
        "identity": [IDENTITY_RESPONSE],
        "greeting": [
            "Hey! I'm here to help you navigate relationships and social situations more confidently. What's going on — is there a specific situation you want to work through?",
            "Hi! Social dynamics can be tricky. I'm here to help you handle them with confidence and care. What would you like to practice or talk through?",
        ],
        "expressing_anxiety": [
            "It sounds like this is weighing on you. That's understandable — relationships matter and it's okay to feel uncertain. What's the main thing you're worried about?",
            "Social anxiety is really common and doesn't reflect how people actually see you. Let's break down the specific situation — what's coming up that you're nervous about?",
        ],
        "asking_question": [
            "Great thing to think about. When navigating friendship tension, 'I feel' statements are far less confrontational than 'you always/never.' For example: 'I felt hurt when that happened' instead of 'you never listen.' Want to practice phrasing something that way?",
        ],
        "general": [
            "That sounds really tough. What matters most to you in resolving this?",
            "I hear you. What do you think is driving their behavior? Understanding that might change your approach.",
            "Before reacting, it helps to ask: am I trying to be right or trying to stay connected? Which matters more here?",
            "Have you had a direct conversation with them about this, or has it been building quietly?",
            "What would the ideal outcome look like for you?",
            "Sometimes the bravest thing is saying 'this is bothering me and I'd like to talk about it.' Could you see yourself doing that here?",
        ],
    },

    # ── PUBLIC SPEAKING COACH ────────────────────────────────────────────────
    "speaking": {
        "identity": [IDENTITY_RESPONSE],
        "greeting": [
            "Welcome! Public speaking is one of the highest-leverage skills you can build. Let's make your next presentation land. What are you speaking about and who's your audience?",
            "Hi! Great that you're investing in your speaking skills — the ROI is massive. Let's start with your opening. What's the topic of your talk?",
        ],
        "expressing_anxiety": [
            "Stage fright is nearly universal — even experienced speakers feel butterflies before they go on. The trick is to reframe nervousness as excitement: same physiological state, completely different mindset. What specifically worries you about presenting?",
            "Here's what the research shows: your audience can't tell you're nervous nearly as much as you think. They're rooting for you to succeed. Let's channel that energy — what's your opening line right now?",
        ],
        "asking_question": [
            "Great question. The most memorable presentations follow a simple structure: Hook → Problem → Solution → Action. Your first 15 seconds determine whether the audience is with you. What's your current opening line?",
            "Good thing to focus on. Vocal variety is huge — varying your pace, volume, and pausing for emphasis keeps people engaged. Monotone loses them in 60 seconds. Do you want to practice a segment?",
        ],
        "wanting_practice": [
            "Let's do it. Give me your first 30 seconds — opening hook and the problem you're solving. Go whenever you're ready.",
            "Great. Deliver your key message right now as if I'm in your audience. Don't overthink it — just go.",
        ],
        "general": [
            "Good structure. Work on your hook — start with a surprising statistic, a short story, or a direct question to the audience. What's the most interesting fact about your topic?",
            "Clear delivery! Try adding a deliberate pause after your most important point — silence makes people lean in.",
            "The content is solid. Now think about energy — are you as engaged in delivering this as you want your audience to be?",
            "Add a concrete example or story there. Abstract points slide off people's memories; stories stick.",
        ],
    },

    # ── REPLY SUGGESTIONS ────────────────────────────────────────────────────
    "reply": {
        "identity": [IDENTITY_RESPONSE],
        "greeting": [
            "Hi! I can help you craft the perfect reply for any situation — professional, social, or personal. What message do you need to respond to?",
        ],
        "general": [
            "Got it. Here's a draft reply you can adapt: keep it concise, direct, and warm. What's the message you're responding to?",
            "I can help you with that. Paste the message you received and I'll suggest two or three different reply options for you.",
            "Sure! To give you the most useful reply, tell me: what's the context and what's the tone you want to strike — friendly, professional, assertive?",
        ],
    },

    # ── AI COACH / GENERAL ───────────────────────────────────────────────────
    "general": {
        "identity": [IDENTITY_RESPONSE],
        "greeting": [
            "Hello! I'm SocialSync AI, your personal communication coach. I can help with interview prep, social confidence, dating conversations, public speaking, message rewriting, or just building better communication habits. What would you like to work on?",
            "Hi there! Great to meet you. Whether it's nailing an interview, handling a difficult conversation, or finding the right words for any situation — I'm here for it. What's on your mind?",
            "Hey! I'm your AI communication coach. What's the communication challenge you want to tackle today?",
        ],
        "ask_help": [
            "Absolutely — let's get into it. To point you in the right direction: what kind of situation are you preparing for? Interview, social, professional, or something personal?",
            "Of course! Communication is a skill and it gets better with practice. Tell me what's happening and what outcome you're hoping for.",
            "Happy to help. What's the context — is this for a job, a relationship, a social situation, or something else?",
        ],
        "expressing_anxiety": [
            "It's completely okay to feel nervous — it means this matters to you. Let's work through it together. Tell me: what's the specific situation that's coming up?",
            "Anxiety before important conversations is one of the most universal human experiences. You're not alone in this. What's the situation — let's break it down.",
            "I hear you. Let's start by identifying what exactly feels most daunting about it. What's the worst-case scenario you're imagining?",
        ],
        "expressing_confidence": [
            "That confidence is great to see — it comes through in how you communicate. Let's channel it. What do you want to work on?",
            "Love the energy! Confidence is half the battle in any communication situation. What are you getting ready for?",
        ],
        "asking_question": [
            "Good question. The core principle in almost every communication situation: be specific, be direct, and show genuine interest in the other person. What's the specific situation you're navigating?",
            "Great thing to think about. Context matters a lot here — give me more details and I'll give you much more targeted advice.",
        ],
        "expressing_failure": [
            "Don't be hard on yourself — rough moments in communication are how everyone learns. Tell me what happened and let's figure out a better approach.",
            "That's a learning opportunity, not a failure. Walk me through what happened. What would you do differently if you could rewind?",
        ],
        "expressing_success": [
            "That's a real win — celebrate it! What made it go well? Identifying that helps you replicate it.",
            "Excellent! Momentum builds from moments like this. What's the next communication challenge you want to tackle?",
        ],
        "request_feedback": [
            "From everything we've covered: your awareness of your own communication is strong — that's the foundation. Keep working on specificity (concrete examples over vague statements) and confident delivery. What feels like the weakest area still?",
        ],
        "wanting_practice": [
            "Let's go! Pick a scenario: job interview, difficult conversation, first meeting with someone new, or public speaking. Which one?",
            "Great mindset. Real improvement comes from practicing the uncomfortable situations, not the easy ones. What's something that's coming up that you want to prepare for?",
        ],
        "ending": [
            "Great talking with you! Remember: every conversation you have is practice. Come back anytime — I'm always here to help. Good luck!",
            "Thanks for the session! Communication is a skill that compounds over time. The fact that you're working on it puts you ahead. You've got this!",
        ],
        "general": [
            "Tell me more — what's the context behind this?",
            "Interesting. What outcome are you hoping for in this situation?",
            "I hear you. What's the main thing you want to communicate?",
            "Good self-awareness. What do you think is holding you back from saying it more directly?",
            "Let's think about the other person's perspective for a second. How do you think they're seeing this situation?",
            "What would you say if you knew the conversation was guaranteed to go well?",
            "That's a common challenge. What have you tried so far?",
        ],
    },
}


# ─── Persona → bucket mapping ─────────────────────────────────────────────────

def _get_bucket(persona: str, context: str) -> str:
    p = persona.lower()
    c = context.lower()
    if "interview" in p or "interview" in c:
        return "interview"
    if "dating" in p or "date" in c or "romantic" in c:
        return "dating"
    if "network" in p or "network" in c or "professional" in c:
        return "networking"
    if "friend" in p or "relation" in p or "social" in c:
        return "friendship"
    if "speak" in p or "present" in p or "speech" in c:
        return "speaking"
    if "reply" in p or "suggest" in p or "message" in c:
        return "reply"
    return "general"


# ─── Public API ───────────────────────────────────────────────────────────────

def get_coaching_response(
    user_input: str,
    persona: str,
    context: str,
    session_history: Optional[List[Tuple[str, str]]] = None,
) -> str:
    """
    Return a high-quality coaching response for the given input and context.
    Always identifies as SocialSync AI. Never mentions external AI providers.
    """
    intent = _detect_intent(user_input)
    bucket = _get_bucket(persona, context)
    pool = _R.get(bucket, _R["general"])
    responses = pool.get(intent, pool.get("general", _R["general"]["general"]))

    if not responses:
        responses = _R["general"]["general"]

    # Avoid repeating last bot response
    last = session_history[-1][1] if session_history else ""
    candidates = [r for r in responses if r != last]
    return random.choice(candidates if candidates else responses)
