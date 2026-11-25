import json, numpy as np, soundfile as sf, re
from kokoro_onnx import Kokoro
k = Kokoro("/home/claude/tts/kokoro.onnx", "/home/claude/tts/voices.bin")
SP=1.17
SEG = [
 ("h1","A guard pokes a sleeping prisoner on the head...",0.12),
 ("h2","and the head falls off, and smashes on the floor.",0.3),
 ("s1","Alcatraz, nineteen sixty-two. The prison everyone calls escape-proof.",0.1),
 ("s2","Freezing water on every side. Guards on every tower.",0.25),
 ("p1","But inmate Frank Morris has a plan.",0.08),
 ("p2","His tools? Spoons. From the cafeteria.",0.2),
 ("e1","Every night, Frank and the Anglin brothers scrape at the tiny air vents behind their sinks.",0.08),
 ("e2","Spoons against concrete? That should take a hundred years.",0.2),
 ("e3","So they build a drill out of a broken vacuum cleaner.",0.06),
 ("e4","Way too loud.",0.06),
 ("e5","So Frank plays the accordion during music hour, to cover the noise.",0.25),
 ("m1","Wait... what about the guards checking the beds at night?",0.25),
 ("y1","You see, they sculpt fake heads out of soap, toothpaste and toilet paper,",0.04),
 ("y2","paint them skin-colored, and glue on real hair from the prison barbershop.",0.1),
 ("y3","In the dark, it looks exactly like a guy asleep.",0.2),
 ("r1","Then they glue fifty raincoats into a raft, and pump it up with a tiny accordion.",0.25),
 ("x1","June eleventh, ten P M.",0.06),
 ("x2","They squeeze through the holes, climb the pipes to the roof, sneak down to the water...",0.08),
 ("x3","and paddle into the dark.",0.35),
 ("n1","Next morning, the guard pokes the head.",0.3),
 ("f1","The F B I searches for seventeen years, and never finds them.",0.2),
 ("l1","Then, in twenty thirteen, police get a letter.",0.12),
 ("l2","My name is John Anglin. We all made it that night.",0.35),
 ("c1","The case?",0.15),
 ("c2","Still open.",0.6),
]
SR=24000; out=[np.zeros(int(SR*0.1),np.float32)]; t=0.1; segs=[]; words=[]
for sid,text,pause in SEG:
    s,sr = k.create(text, voice="am_puck", speed=SP, lang="en-us"); s=s.astype(np.float32)
    a=np.abs(s); idx=np.where(a>0.01*a.max())[0]; s=s[max(0,idx[0]-200):min(len(s),idx[-1]+400)]
    d=len(s)/SR; segs.append(dict(id=sid,text=text,start=round(t,3),end=round(t+d,3)))
    toks=re.findall(r"[\w'\-]+",text); w=[len(x)+2 for x in toks]; c=t
    for tok,wi in zip(toks,w):
        dd=d*wi/sum(w); words.append(dict(word=tok,start=round(c,3),end=round(c+dd,3),seg=sid)); c+=dd
    out.append(s); t+=d; out.append(np.zeros(int(SR*pause),np.float32)); t+=pause
y=np.concatenate(out); y=y/np.abs(y).max()*0.89
sf.write("voice.wav", y, SR); json.dump(segs, open("segments.json","w"), indent=1); json.dump(words, open("words.json","w"), indent=1)
print("total", round(t,2), "words", len(words), "wps", round(len(words)/t,2))
for s in segs: print(s["id"], round(s["start"]*30), round(s["end"]*30))
