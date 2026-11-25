import numpy as np, soundfile as sf
from scipy.signal import butter, sosfilt, resample_poly
SR=48000; FPS=30; TOTAL=1880; N=int(TOTAL/FPS*SR)+SR//2
rng=np.random.default_rng(11)
fr=lambda f:int(f/FPS*SR)
lp=lambda x,fc,o=2: sosfilt(butter(o,fc,'low',fs=SR,output='sos'),x)
hp=lambda x,fc,o=2: sosfilt(butter(o,fc,'high',fs=SR,output='sos'),x)
bp=lambda x,a,b,o=2: sosfilt(butter(o,[a,b],'band',fs=SR,output='sos'),x)
def env(n,a,r):
    e=np.ones(n); A=max(1,int(a*SR)); R=max(1,int(r*SR)); A=min(A,n); R=min(R,n)
    e[:A]=np.linspace(0,1,A); e[-R:]*=np.linspace(1,0,R); return e
noise=lambda n: rng.standard_normal(n)
def add(buf,x,at,g=1.0):
    at=max(0,at); n=min(len(x),len(buf)-at)
    if n>0: buf[at:at+n]+=g*x[:n]
def tone(freq,dur,kind='sine',a=0.005,r=0.2):
    n=int(dur*SR); t=np.arange(n)/SR
    if kind=='pluck': x=np.sin(2*np.pi*freq*t)*np.exp(-t*7)+0.3*np.sin(4*np.pi*freq*t)*np.exp(-t*12)
    elif kind=='saw': x=lp(2*((t*freq)%1)-1,2400)
    elif kind=='reed': x=lp(np.sign(np.sin(2*np.pi*freq*t))*0.6+np.sin(2*np.pi*freq*1.004*t),3000)*(1+0.25*np.sin(2*np.pi*6*t))
    elif kind=='bell': x=sum(np.sin(2*np.pi*freq*m*t)*np.exp(-t*d)*g for m,d,g in [(1,2.5,1),(2.76,4,.4),(5.4,7,.2)])
    else: x=np.sin(2*np.pi*freq*t)
    return x*env(n,a,r)
note=lambda n: 440*2**((n-69)/12)
sfx=np.zeros(N); amb=np.zeros(N); mus=np.zeros(N)
def bed(a,b,kind,g):
    n=fr(b)-fr(a); x=noise(n); t=np.arange(n)/SR
    if kind=='hall': x=lp(x,250)*0.6+0.1*np.sin(2*np.pi*60*t)
    if kind=='bay': x=bp(x,100,900)*(0.7+0.3*np.sin(t*0.9))+bp(noise(n),1500,5000)*0.15*(0.5+0.5*np.sin(t*0.4))
    if kind=='day': x=bp(x,120,1200)*0.6
    if kind=='room': x=lp(x,300)*0.25
    add(amb,x*env(n,0.05,0.08),fr(a),g)
bed(0,255,'hall',0.05); bed(342,1216,'hall',0.045); bed(1216,1462,'hall',0.04); bed(1536,1594,'hall',0.05)
bed(255,342,'bay',0.09); bed(1462,1536,'bay',0.1); bed(1594,1690,'day',0.08); bed(1690,1880,'room',0.05)
def whoosh(at,dur=0.5,g=0.3):
    n=int(dur*SR); x=bp(noise(n),400,3000)*np.sin(np.pi*np.linspace(0,1,n))**2; add(sfx,x,fr(at)-n//2,g)
def tap(at,g=0.25):
    n=int(0.12*SR); t=np.arange(n)/SR; add(sfx,bp(noise(n),800,4000)*np.exp(-t*60)+np.sin(2*np.pi*300*t)*np.exp(-t*40),fr(at),g)
def thud(at,g=0.4):
    n=int(0.5*SR); t=np.arange(n)/SR; add(sfx,np.sin(2*np.pi*(80-40*t)*t)*np.exp(-t*10)+lp(noise(n),400)*np.exp(-t*20),fr(at),g)
def smash(at,g=0.45):
    n=int(0.9*SR); t=np.arange(n)/SR; x=hp(noise(n),1500)*np.exp(-t*8)+bp(noise(n),300,1500)*np.exp(-t*14)
    for k in range(6): add(sfx,hp(noise(int(0.05*SR)),2500)*np.exp(-np.arange(int(0.05*SR))/SR*60),fr(at)+int((0.06+k*0.07)*SR),0.2)
    add(sfx,x,fr(at),g); thud(at,0.35)
def step(at,g=0.08):
    n=int(0.1*SR); t=np.arange(n)/SR; add(sfx,lp(noise(n),900)*np.exp(-t*45),fr(at),g)
def scrape(at,dur,g=0.1):
    n=int(dur*SR); t=np.arange(n)/SR; m=0.5+0.5*np.sign(np.sin(2*np.pi*2.2*t)); add(sfx,bp(noise(n),1500,5000)*m*env(n,0.02,0.05),fr(at),g)
def drill(at,dur,g=0.18):
    n=int(dur*SR); t=np.arange(n)/SR; x=np.sign(np.sin(2*np.pi*(180+20*np.sin(t*30))*t))*0.5+bp(noise(n),800,3000)*0.5; add(sfx,lp(x,3500)*env(n,0.05,0.1),fr(at),g)
def pop(at,g=0.15,f0=600): n=int(0.12*SR); add(sfx,np.sin(2*np.pi*f0*np.arange(n)/SR*(1+np.arange(n)/n))*np.exp(-np.arange(n)/SR*28),fr(at),g)
def ding(at,f0=1568,g=0.15): add(sfx,tone(f0,1.0,'bell'),fr(at),g)
def flip(at,g=0.08): n=int(0.15*SR); add(sfx,hp(noise(n),2500)*env(n,0.01,0.1),fr(at),g)
def click(at,g=0.15): n=int(0.04*SR); add(sfx,hp(noise(n),3000)*np.exp(-np.arange(n)/SR*100),fr(at),g)
def clank(at,g=0.12,f0=900): add(sfx,tone(f0,0.4,'bell')*0.6+tone(f0*1.37,0.4,'bell')*0.4,fr(at),g)
def splash(at,g=0.12): n=int(0.4*SR); t=np.arange(n)/SR; add(sfx,bp(noise(n),600,4000)*np.exp(-t*9),fr(at),g)
def wheeze(at,g=0.1): n=int(0.35*SR); add(sfx,bp(noise(n),300,1200)*np.sin(np.pi*np.linspace(0,1,n)),fr(at),g)
# hook
for f in [5,22,38]: step(f)
tap(40); tap(52,0.18); whoosh(80,0.4,0.2); smash(101)
for f in [136,255,342,932,1216,1341,1462,1536,1594,1690]: whoosh(f,0.5,0.22)
# searchlight hum on the bay
n=fr(342)-fr(255); add(amb,np.sin(2*np.pi*55*np.arange(n)/SR)*0.3*env(n,0.3,0.3),fr(255),0.04)
pop(405,0.12,900); ding(405,2093,0.08)
scrape(455,6.5,0.08); scrape(520,4.5,0.05)
for f in range(600,660,8): flip(f)
drill(676,1.9,0.16); thud(742,0.3); add(sfx,tone(note(40),0.6,'saw'),fr(742),0.12)
for f in range(752,860,26): step(f,0.05)
click(861,0.2); add(sfx,tone(note(76),0.4,'bell')+tone(note(81),0.4,'bell'),fr(895),0.12)
for f in [985,995,1015,1028]: pop(f,0.13,700+(f%7)*60)
ding(1045,1760,0.1); ding(1096,2093,0.1)
click(1150,0.15)
for f in range(1282,1340,10): wheeze(f,0.08)
for f in [1388,1400]: scrape(f,0.4,0.08)
for f in range(1420,1462,9): clank(f,0.07,700+(f%5)*90)
for f in range(1490,1536,14): splash(f,0.1)
for f in [1540,1552]: step(f)
tap(1560); smash(1588)
n=fr(1690)-fr(1594); t=np.arange(n)/SR; add(amb,lp(np.sign(np.sin(2*np.pi*40*t)),300)*env(n,0.3,0.3),fr(1594),0.05)
for f in range(1615,1690,7): flip(f,0.05)
flip(1705,0.1); flip(1736,0.12); flip(1745,0.08)
thud(1850,0.25); add(sfx,tone(note(36),2.0,'sine',0.01,1.0),fr(1850),0.3)

# ---- music: sneaky minor heist groove (A minor), accordion diegetic at 775-860, mysterious ending ----
BPM=120; beat=60/BPM
def seq(a,b,notes,bass,kind='pluck',g=0.1,step=0.5):
    t=a/FPS; i=0
    while t<b/FPS-0.05:
        n=notes[i%len(notes)]
        if n is not None: add(mus,tone(note(n),0.45,kind),int(t*SR),g)
        if i%4==0: add(mus,tone(note(bass[(i//4)%len(bass)]),beat*1.8,'sine',0.01,0.3),int(t*SR),g*1.1)
        t+=beat*step; i+=1
def hat(a,b,g=0.03):
    t=a/FPS
    while t<b/FPS: n=int(0.04*SR); add(mus,hp(noise(n),6000)*np.exp(-np.arange(n)/SR*90),int(t*SR),g); t+=beat/2
seq(0,255,[69,None,72,None,76,75,None,72],[45,45,41,40],g=0.08)
seq(255,342,[64,None,None,67,None,None,64,None],[40],kind='sine',g=0.06)
seq(342,775,[69,72,76,72,74,None,71,None],[45,41,43,40],g=0.08); hat(449,775)
# accordion tune (diegetic, cheerful)
for i,n in enumerate([72,74,76,77,79,77,76,74,72,76,79,84]): add(mus,tone(note(n),0.32,'reed',0.02,0.08),fr(775)+int(i*0.25*SR),0.07)
for i,n in enumerate([60,64,67,64]*3): add(mus,tone(note(n),0.24,'reed',0.02,0.08),fr(775)+int(i*0.25*SR),0.04)
seq(861,932,[None,64,None,63],[40],kind='sine',g=0.06)
seq(932,1216,[69,None,72,74,76,None,79,76],[45,41,43,45],g=0.08); hat(932,1216)
seq(1216,1536,[69,72,76,79,77,76,72,71],[45,41,43,40],g=0.09); hat(1216,1536,0.04)
seq(1536,1690,[69,None,None,68],[45,40],kind='sine',g=0.06)
for n in [57,60,64,67]: add(mus,tone(note(n),6.0,'sine',0.5,2.5),fr(1700),0.035)
add(mus,tone(note(81),2.5,'bell'),fr(1850),0.08); add(mus,tone(note(75),2.5,'bell'),fr(1852),0.06)

v,vsr=sf.read('/home/claude/alcatraz/voice/voice.wav'); v=resample_poly(v,SR,vsr); voice=np.zeros(N); voice[:len(v)]=v[:N]
venv=np.convolve(np.abs(voice),np.ones(SR//10)/(SR//10),'same'); duck=1-0.4*np.clip(venv/0.05,0,1); duck=np.convolve(duck,np.ones(SR//20)/(SR//20),'same')
music=lp(mus,6500)*duck*0.75; effects=(sfx+amb)*0.55
mix=voice+music+effects; mix=mix/np.abs(mix).max(); mix=np.tanh(mix*1.5)/np.tanh(1.5); mix=mix/np.abs(mix).max()*0.8; mix=mix[:fr(TOTAL)]
sf.write('mix.wav',np.stack([mix,mix],1),SR)
db=lambda x:20*np.log10(np.sqrt(np.mean(x**2))+1e-9)
for nm,a,b in [('hook',0,255),('plan',342,860),('acc',775,860),('heads',932,1216),('escape',1341,1536),('end',1690,1880)]:
    s,e=fr(a),fr(b); print(nm,'voice %.1f music %.1f fx %.1f'%(db(voice[s:e]),db(music[s:e]),db(effects[s:e])))
