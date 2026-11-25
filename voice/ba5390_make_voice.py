import json, numpy as np, soundfile as sf, re
from kokoro_onnx import Kokoro
k = Kokoro("/home/claude/tts/kokoro.onnx", "/home/claude/tts/voices.bin")
# (id, text, pause_after_seconds, speed)
SEG = [
 ("hook1","Twenty-seven hours before take-off, a mechanic grabbed the wrong bolts.",0.25,1.12),
 ("hook2","That's why this captain is about to end up outside his own plane.",0.55,1.12),
 ("set1","June, 1990.",0.2,1.05),
 ("set2","British Airways Flight fifty-three ninety leaves Birmingham for sunny Malaga.",0.2,1.12),
 ("set3","Eighty-one passengers. Six crew.",0.5,1.08),
 ("snap1","Thirteen minutes in.",0.15,1.08),
 ("bang","Bang!",0.3,1.0),
 ("snap2","The captain's windscreen blows out at seventeen thousand feet.",0.35,1.12),
 ("suck1","All the air in the cabin rushes for the hole...",0.15,1.12),
 ("suck2","and takes the captain with it. Right out of his seatbelt.",0.45,1.12),
 ("nig1","A steward named Nigel lunges and grabs his legs.",0.2,1.12),
 ("nig2","In that wind, the captain feels like he weighs five hundred pounds.",0.2,1.12),
 ("nig3","Now Nigel is sliding out too.",0.15,1.12),
 ("nig4","More crew rush in and grab Nigel.",0.5,1.12),
 ("exp1","Here's what happened.",0.15,1.12),
 ("exp2","A plane in the sky is like a balloon. The air inside pushes outward, all the time.",0.2,1.14),
 ("exp3","That windscreen was held by ninety bolts.",0.15,1.12),
 ("exp4","Eighty-four were too thin, by less than the thickness of a credit card.",0.2,1.12),
 ("exp5","The mechanic had picked them by eye, from a drawer.",0.5,1.12),
 ("hold1","The crew thinks the captain is dead.",0.15,1.08),
 ("hold2","They hold on anyway. If they let go, he could hit the engine.",0.45,1.12),
 ("land1","Twenty minutes later, the co-pilot lands in Southampton.",0.45,1.12),
 ("end1","The captain?",0.25,1.08),
 ("end2","Frostbite. Broken bones. Alive.",0.5,1.05),
 ("end3","And five months later... he was flying again.",0.8,1.05),
]
SR=24000; out=[]; t=0.25; out.append(np.zeros(int(SR*0.25),np.float32)); segs=[]; words=[]
for sid,text,pause,sp in SEG:
    s,sr = k.create(text, voice="am_puck", speed=sp, lang="en-us")
    s=s.astype(np.float32)
    # trim silence
    a=np.abs(s); thr=0.01*a.max(); idx=np.where(a>thr)[0]
    s=s[max(0,idx[0]-240):min(len(s),idx[-1]+480)]
    d=len(s)/SR
    segs.append(dict(id=sid,text=text,start=round(t,3),end=round(t+d,3)))
    toks=re.findall(r"[\w'\-\.]+",text); w=[len(x)+2 for x in toks]; tot=sum(w); c=t
    for tok,wi in zip(toks,w):
        dd=d*wi/tot; words.append(dict(word=tok,start=round(c,3),end=round(c+dd,3),seg=sid)); c+=dd
    out.append(s); t+=d
    out.append(np.zeros(int(SR*pause),np.float32)); t+=pause
y=np.concatenate(out); y=y/np.abs(y).max()*0.89
sf.write("/home/claude/ba5390/voice/voice.wav", y, SR)
json.dump(segs, open("/home/claude/ba5390/voice/segments.json","w"), indent=1)
json.dump(words, open("/home/claude/ba5390/voice/words.json","w"), indent=1)
print("total", round(t,2))
for s in segs: print(s["id"], s["start"], s["end"])
