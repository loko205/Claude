# Synthesized SFX + original score + mix for the BA 5390 short (48 kHz). Event times in frames (30 fps).
import numpy as np, soundfile as sf, json
from scipy.signal import butter, sosfilt, resample_poly
SR = 48000; FPS = 30; TOTAL = 1890; N = int(TOTAL / FPS * SR) + SR // 2
rng = np.random.default_rng(7)
def fr(f): return int(f / FPS * SR)
def lp(x, fc, o=2): return sosfilt(butter(o, fc, 'low', fs=SR, output='sos'), x)
def hp(x, fc, o=2): return sosfilt(butter(o, fc, 'high', fs=SR, output='sos'), x)
def bp(x, a, b, o=2): return sosfilt(butter(o, [a, b], 'band', fs=SR, output='sos'), x)
def env(n, a, r, sus=None):
    e = np.ones(n); A = max(1, int(a * SR)); R = max(1, int(r * SR))
    e[:A] = np.linspace(0, 1, A); e[-R:] *= np.linspace(1, 0, R); return e
def noise(n): return rng.standard_normal(n)
def add(buf, x, at, g=1.0):
    at = max(0, at); n = min(len(x), len(buf) - at)
    if n > 0: buf[at:at + n] += g * x[:n]
def tone(freq, dur, kind='sine', a=0.005, r=0.2):
    n = int(dur * SR); t = np.arange(n) / SR
    if kind == 'pluck':
        x = np.sin(2 * np.pi * freq * t) * np.exp(-t * 6) + 0.3 * np.sin(4 * np.pi * freq * t) * np.exp(-t * 10)
    elif kind == 'saw':
        x = 2 * ((t * freq) % 1) - 1; x = lp(x, 2500)
    elif kind == 'bell':
        x = sum(np.sin(2 * np.pi * freq * m * t) * np.exp(-t * d) * g for m, d, g in [(1, 2.5, 1), (2.76, 4, .4), (5.4, 7, .2)])
    else:
        x = np.sin(2 * np.pi * freq * t)
    return x * env(n, a, r)
def note(n): return 440 * 2 ** ((n - 69) / 12)

sfx = np.zeros(N); amb = np.zeros(N); mus = np.zeros(N)
# ---------- ambience beds ----------
def bed(a, b, kind, g):
    n = fr(b) - fr(a); x = noise(n)
    if kind == 'hangar': x = lp(x, 300) * 0.6 + 0.15 * np.sin(2 * np.pi * 60 * np.arange(n) / SR)
    if kind == 'jet': x = bp(x, 200, 2500) * 0.5 + lp(noise(n), 120) * 0.8
    if kind == 'cabin': x = lp(x, 500) * 0.7
    if kind == 'wind': x = bp(x, 300, 4000) * (0.8 + 0.4 * np.sin(np.arange(n) / SR * 3.1) * np.sin(np.arange(n) / SR * 1.3))
    if kind == 'runway': x = bp(x, 150, 3000) * 0.6 + lp(noise(n), 100)
    if kind == 'room': x = lp(x, 400) * 0.3
    x = x * env(n, 0.05, 0.08)
    add(amb, x, fr(a), g)
bed(0, 118, 'hangar', 0.05); bed(1378, 1450, 'hangar', 0.05)
bed(118, 222, 'jet', 0.05); bed(222, 398, 'runway', 0.07); bed(398, 458, 'jet', 0.06); bed(458, 493, 'cabin', 0.05)
bed(493, 1050, 'wind', 0.06); bed(1050, 1378, 'jet', 0.035); bed(1450, 1595, 'wind', 0.055); bed(1595, 1692, 'runway', 0.07)
bed(1692, 1790, 'room', 0.05); bed(1790, 1890, 'cabin', 0.04)
# ---------- SFX ----------
def clink(at, g=0.25, f0=2600):
    x = tone(f0, 0.25, 'bell') + 0.6 * tone(f0 * 1.5, 0.25, 'bell'); add(sfx, x, fr(at), g)
def whoosh(at, dur=0.5, g=0.35, up=True):
    n = int(dur * SR); x = noise(n); t = np.linspace(0, 1, n)
    out = np.zeros(n); seg = n // 8
    for i in range(8):
        lo = 300 + (i if up else 7 - i) * 350; s = bp(x[i * seg:(i + 1) * seg + seg], lo, lo * 2.5)[:len(out[i * seg:(i + 1) * seg + seg])]
        out[i * seg:i * seg + len(s)] += s
    out *= np.sin(np.pi * t) ** 2; add(sfx, out, fr(at) - n // 2, g)
def bang(at):
    n = int(1.6 * SR); t = np.arange(n) / SR
    x = noise(n) * np.exp(-t * 5); x = lp(x, 3000) * 1.2 + lp(noise(n), 150) * np.exp(-t * 3) * 2.5 + np.sin(2 * np.pi * 45 * t) * np.exp(-t * 4) * 1.5
    add(sfx, x, fr(at), 0.55)
def creak(at, dur=0.5, g=0.18):
    n = int(dur * SR); t = np.arange(n) / SR; f = 180 + 60 * np.sin(t * 23)
    x = np.sign(np.sin(2 * np.pi * np.cumsum(f) / SR)) * (0.5 + 0.5 * np.sin(t * 70)); x = bp(x, 200, 2000) * env(n, 0.02, 0.1); add(sfx, x, fr(at), g)
def thud(at, g=0.4):
    n = int(0.5 * SR); t = np.arange(n) / SR; x = np.sin(2 * np.pi * (70 - 30 * t) * t) * np.exp(-t * 9) + lp(noise(n), 400) * np.exp(-t * 20)
    add(sfx, x, fr(at), g)
def screech(at, dur=0.8, g=0.18):
    n = int(dur * SR); t = np.arange(n) / SR; x = bp(noise(n), 1800, 3200) * env(n, 0.01, 0.4) + 0.3 * np.sin(2 * np.pi * 2300 * t) * env(n, 0.01, 0.4)
    add(sfx, x, fr(at), g)
def flutter(at, dur=0.6, g=0.12):
    n = int(dur * SR); t = np.arange(n) / SR; x = hp(noise(n), 2000) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 18 * t))) * env(n, 0.02, 0.2); add(sfx, x, fr(at), g)
def ding(at, f0=1568, g=0.2): add(sfx, tone(f0, 1.2, 'bell'), fr(at), g)
def beep(at, g=0.07): add(sfx, tone(1000, 0.12, 'sine', 0.003, 0.02), fr(at), g)
def pop(at, g=0.15): add(sfx, tone(500, 0.12, 'sine', 0.002, 0.08) * np.exp(-np.arange(int(0.12 * SR)) / SR * 30), fr(at), g)
# hangar: bolt clinks from the drawer, the hook
for f in [20, 34, 52, 88]: clink(f, 0.18, 2400 + 300 * (f % 3))
whoosh(116, 0.5, 0.3)
whoosh(220, 0.6, 0.4)                       # into the take-off
add(sfx, lp(noise(fr(398) - fr(300)), 300) * env(fr(398) - fr(300), 0.5, 0.5), fr(300), 0.12)  # engine spool-up rumble
whoosh(396, 0.5, 0.25)
for f in [478, 484, 489]: creak(f, 0.18, 0.14)
bang(493); bang(509)                         # inside + the cut outside
for i in range(8): clink(520 + i * 4, 0.12, 2000 + i * 150)
whoosh(612, 0.5, 0.3, False)
for f in range(625, 740, 17): flutter(f, 0.4, 0.08)
whoosh(690, 0.8, 0.5)                        # captain goes
add(sfx, hp(noise(int(0.4 * SR)), 1500) * env(int(0.4 * SR), 0.01, 0.2), fr(712), 0.12)  # cap whoosh
thud(GRAB := 800, 0.35)
add(sfx, lp(noise(int(1.2 * SR)), 200) * env(int(1.2 * SR), 0.05, 0.6), fr(862), 0.35)   # heavy weight drop
thud(874, 0.45)
for f in [952, 975]: add(sfx, bp(noise(int(0.5 * SR)), 300, 1200) * env(int(0.5 * SR), 0.05, 0.3), fr(f), 0.12)  # shoe squeak / slide
for f in [995, 1005]: thud(f, 0.25)
whoosh(1050, 0.5, 0.3)
for f in [1105, 1120, 1135, 1150, 1165, 1180]: pop(f, 0.1)       # balloon breathing
whoosh(1213, 0.5, 0.25)
for i, f in enumerate(range(1290, 1300, 1)): pass
ding(1290, 880, 0.18); ding(1293, 932, 0.14)                     # "too thin" red
whoosh(1318, 0.4, 0.2); add(sfx, hp(noise(int(0.3 * SR)), 2500) * env(int(0.3 * SR), 0.01, 0.2), fr(1340), 0.12)  # card slide
whoosh(1378, 0.5, 0.25)
for f in [1395, 1415, 1432]: clink(f, 0.14, 2700)
whoosh(1450, 0.5, 0.3)
whoosh(1540, 1.0, 0.25)
whoosh(1595, 0.5, 0.3)
screech(1648, 0.9, 0.2); thud(1648, 0.4)
whoosh(1690, 0.6, 0.25)
for f in range(1700, 1790, 24): beep(f)
ding(1765, 1318, 0.12)
whoosh(1790, 0.6, 0.25)
ding(1850, 1568, 0.16); ding(1853, 2093, 0.12)

# ---------- music (original): C major, light pizzicato + bass; tension section in minor; resolution ----------
BPM = 112; beat = 60 / BPM
def seq(a, b, notes, bassline, kind='pluck', g=0.12, step=0.5):
    t0 = a / FPS; t1 = b / FPS; i = 0; t = t0
    while t < t1 - 0.05:
        n = notes[i % len(notes)]
        if n is not None: add(mus, tone(note(n), 0.5, kind), int(t * SR), g)
        if i % 4 == 0:
            bn = bassline[(i // 4) % len(bassline)]; add(mus, tone(note(bn), beat * 2, 'sine', 0.01, 0.3), int(t * SR), g * 0.9)
        t += beat * step; i += 1
# hook (sneaky, staccato)
seq(0, 222, [72, None, 76, 79, 77, None, 74, None], [48, 45, 43, 45], g=0.10)
# take-off: brighter
seq(222, 458, [79, 76, 72, 76, 81, 79, 76, 74], [48, 53, 55, 48], g=0.10)
# cockpit calm before
seq(458, 490, [76, None, 74, None], [48], g=0.07)
# BANG: stop, then low tension pulse in A minor
def pulse(a, b, root, g):
    t = a / FPS
    while t < b / FPS:
        add(mus, tone(note(root), 0.18, 'saw', 0.005, 0.1), int(t * SR), g); t += beat / 2
pulse(520, 1050, 33, 0.07)
seq(612, 1050, [69, None, 72, None, 71, None, 68, None], [45, 45, 44, 44], kind='pluck', g=0.07)
# explanation: playful again
seq(1050, 1450, [72, 74, 76, None, 79, None, 76, 74], [48, 43, 45, 41], g=0.08)
# holding on: tension again
pulse(1450, 1595, 33, 0.07); seq(1450, 1595, [69, None, 72, 76, None, 72], [45, 41], g=0.06)
# landing + ending: warm resolution
seq(1595, 1790, [76, 79, 84, 79, 77, 81, 84, 81], [48, 53, 43, 48], g=0.09)
for n in [60, 64, 67, 72]: add(mus, tone(note(n), 3.0, 'sine', 0.3, 1.5), fr(1796), 0.06)
seq(1790, 1860, [84, 79, 76, 72], [48], g=0.08)
add(mus, tone(note(84), 1.5, 'bell'), fr(1858), 0.12)

# ---------- voice + ducking + mix ----------
v, vsr = sf.read('/home/claude/ba5390/voice/voice.wav')
v = resample_poly(v, SR, vsr); voice = np.zeros(N); voice[:len(v)] = v[:N]
venv = np.convolve(np.abs(voice), np.ones(SR // 10) / (SR // 10), 'same'); duck = 1 - 0.45 * np.clip(venv / 0.05, 0, 1)
duck = np.convolve(duck, np.ones(SR // 20) / (SR // 20), 'same')
music = lp(mus, 6000) * duck * 0.6
effects = (sfx + amb) * 0.5           # -6 dB
mix = voice * 1.0 + music + effects
mix = np.tanh(mix * 1.1) / np.tanh(1.1)
peak = np.abs(mix).max(); mix = mix / peak * 0.89
end = fr(TOTAL); mix = mix[:end]
st = np.stack([mix, mix], 1)
sf.write('/home/claude/ba5390/audio/mix.wav', st, SR)
print('peak', peak, 'len', len(mix) / SR)
def db(x): return 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-9)
for name, a, b in [("hook", 0, 222), ("bang", 493, 612), ("nigel", 757, 1050), ("explain", 1050, 1450), ("end", 1692, 1890)]:
    s, e = fr(a), fr(b)
    print(name, "voice %.1f music %.1f fx %.1f" % (db(voice[s:e]), db(music[s:e]), db(effects[s:e])))
