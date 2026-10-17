from pathlib import Path
from fontTools import subset
import wave,math,struct,random
ROOT=Path(__file__).resolve().parents[2]/'maze3d'
text=''.join(p.read_text() for p in (ROOT/'scripts').glob('*.gd'))+''.join(chr(i) for i in range(32,127))+'→←↑↓×Ⅱ0123456789'
for target,source in [('regular','NotoSansCJK-Regular'),('bold','NotoSansCJK-Bold'),('title','NotoSerifCJK-Regular')]:
    opts=subset.Options();opts.font_number=2
    font=subset.load_font('/usr/share/fonts/opentype/noto/'+source+'.ttc',opts)
    sub=subset.Subsetter(options=opts);sub.populate(text=text);sub.subset(font)
    subset.save_font(font,str(ROOT/'assets'/('ui-'+target+'.otf')),opts)
rate=22050
random.seed(42)
def save(name,duration,fn):
    with wave.open(str(ROOT/'assets/audio'/(name+'.wav')),'w') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate)
        f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(i/rate)))*24000)) for i in range(int(duration*rate))))
def note(t,f):return (math.sin(t*f*math.tau)+.28*math.sin(t*f*math.tau*2))*.24*math.exp(-t*4.2)*(1-math.exp(-t*120)) if t>=0 else 0
def chord(t,notes):return sum(note(t-i*.12,f) for i,f in enumerate(notes))*.7
save('mote',.7,lambda t:chord(t,[880,1320]))
save('beacon',1.7,lambda t:chord(t,[440,554.37,659.25,880]))
save('hint',1,lambda t:chord(t,[659.25,880,987.77]))
save('win',2.7,lambda t:chord(t,[392,493.88,587.33,783.99,987.77,1174.66]))
save('step',.14,lambda t:(random.random()-.5)*.35*math.exp(-t*38)+math.sin(t*100*math.tau)*.16*math.exp(-t*45))
save('jump',.28,lambda t:math.sin(math.tau*(280*t+500*t*t))*.20*math.sin(math.pi*t/.28)**2)
# A seamless, sparse ambient pad, with harmonics quantized to the 24-second loop.
def ambient(t):
    pad=sum(math.sin(t*math.tau*f)*v for f,v in [(130.833333,.12),(196,.065),(261.666667,.055),(329.625,.035)])
    pad*=.72+.18*math.sin(t*math.tau/24)
    bells=sum(note(t-off,fr)*.13 for off,fr in [(3,659.25),(7,587.33),(12,440),(17,783.99),(21,659.25)])
    return pad+bells
save('ambience',24,ambient)
print('ASSETS: subset fonts and eight original synthesized audio cues')
