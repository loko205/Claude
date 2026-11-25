"""Lottery short voice: Kokoro am_puck, per-sentence synthesis, word timings via prefix synthesis + energy snap.
Run from repo root: python3 voice/lottery_make_voice.py  -> remotion/public/lottery/{voice.wav,words.json,segments.json}
"""
import json, re, os
import numpy as np, soundfile as sf
from kokoro_onnx import Kokoro

K = Kokoro("/home/claude/tts/kokoro.onnx", "/home/claude/tts/voices.bin")
SP = 1.16
OUT = "remotion/public/lottery"
SEG = [  # id, text, pause after (s)
    ("h1", "An old man spent thirty-six hundred dollars on lottery tickets, and prayed nobody would hit the jackpot.", 0.12),
    ("s1", "You see, he's sold lottery tickets in his own little store for years, and never bought a single one.", 0.06),
    ("s2", "Then a new game shows up, he reads the rules on the back, and three minutes later he's emptying his savings.", 0.08),
    ("m0", "The kid behind the counter prints tickets for an hour straight.", 0.04),
    ("m1", "Grandpa, you know you only need one to win, right?", 0.08),
    ("e1", "He doesn't answer. He just stares at the jackpot sign.", 0.1),
    ("e2", "Draw night, nobody hits the jackpot, and he walks out with sixty-three hundred dollars.", 0.06),
    ("m2", "Beginner's luck, says the kid.", 0.1),
    ("e3", "So next time, he brings his wife, and they buy so many tickets the kid misses his lunch break.", 0.04),
    ("m3", "You two are gonna lose the house.", 0.14),
    ("q1", "Wait, why would anyone want nobody to win?", 0.1),
    ("y1", "You see, this game had one weird rule.", 0.04),
    ("y2", "When the jackpot got huge and nobody won it, the money got split between everyone who matched just a few numbers.", 0.06),
    ("y3", "It's like a birthday party where the birthday kid never shows up.", 0.04),
    ("y4", "Nobody gets the whole cake, so everyone's slice gets way bigger.", 0.06),
    ("y5", "And once every slice was worth more than a ticket, buying more tickets wasn't gambling. It was math.", 0.14),
    ("p1", "For nine years, he and his wife only played on those nights, and won twenty-six million dollars.", 0.08),
    ("p2", "And the kid who laughed printed every single ticket.", 0.5),
]
SR = 24000


def synth(text):
    s, _ = K.create(text, voice="am_puck", speed=SP, lang="en-us")
    s = s.astype(np.float32)
    a = np.abs(s)
    idx = np.where(a > 0.01 * a.max())[0]
    return s[max(0, idx[0] - 200):min(len(s), idx[-1] + 400)]


def snap(sig, t, win=0.07):
    """Move a boundary to the quietest 10 ms within +-win seconds."""
    hop = int(0.01 * SR)
    lo, hi = max(0, int((t - win) * SR)), min(len(sig), int((t + win) * SR))
    best, bt = 1e9, t
    for i in range(lo, max(lo + 1, hi - hop), hop // 2):
        e = float(np.mean(sig[i:i + hop] ** 2))
        if e < best:
            best, bt = e, (i + hop / 2) / SR
    return bt


os.makedirs(OUT, exist_ok=True)
out = [np.zeros(int(SR * 0.08), np.float32)]
t = 0.08
segs, words = [], []
for sid, text, pause in SEG:
    s = synth(text)
    d = len(s) / SR
    toks = re.findall(r"[\w'\-]+[.,?!]?", text)
    # prefix synthesis -> approximate end time of each word
    ends = []
    for i in range(1, len(toks)):
        pre = " ".join(toks[:i]).rstrip(",")
        ends.append(min(d, len(synth(pre)) / SR - 0.015))
    ends.append(d)
    # monotonic + snap to quiet spots
    fixed, prev = [], 0.0
    for e in ends[:-1]:
        e = snap(s, max(prev + 0.06, e))
        fixed.append(max(prev + 0.06, min(e, d - 0.05)))
        prev = fixed[-1]
    fixed.append(d)
    st = 0.0
    for tok, e in zip(toks, fixed):
        words.append(dict(word=re.sub(r"[.,?!]$", "", tok), start=round(t + st, 3), end=round(t + e, 3), seg=sid,
                          punct=tok[-1] if tok[-1] in ".,?!" else ""))
        st = e
    segs.append(dict(id=sid, text=text, start=round(t, 3), end=round(t + d, 3)))
    out.append(s)
    t += d
    out.append(np.zeros(int(SR * pause), np.float32))
    t += pause

y = np.concatenate(out)
y = y / np.abs(y).max() * 0.89
sf.write(f"{OUT}/voice.wav", y, SR)
json.dump(segs, open(f"{OUT}/segments.json", "w"), indent=1)
json.dump(words, open(f"{OUT}/words.json", "w"), indent=1)
print("total", round(t, 2), "s  frames", int(np.ceil(t * 30)), " words", len(words), " wps", round(len(words) / t, 2))
for s_ in segs:
    print(s_["id"], round(s_["start"] * 30), round(s_["end"] * 30), s_["text"][:50])
