"""Generate original short PCM cues; no downloaded audio assets."""
from pathlib import Path
import wave, math, struct
folder=Path(__file__).resolve().parents[1]/'app/src/main/res/raw'
folder.mkdir(parents=True,exist_ok=True)
def write(name,events,duration):
 rate=22050; data=bytearray()
 for i in range(int(rate*duration)):
  t=i/rate;value=0
  for start,freq,length,gain in events:
   x=t-start
   if 0<=x<length:
    env=min(1,x/.008)*(1-x/length)**2
    value+=gain*env*(math.sin(2*math.pi*freq*x)+.16*math.sin(4*math.pi*freq*x))
  data.extend(struct.pack('<h',int(max(-1,min(1,value))*24000)))
 with wave.open(str(folder/(name+'.wav')),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(data)
for i,n in enumerate([523.25,587.33,659.25,783.99,880,1046.5]):write('hit'+str(i),[(0,n,.13,.55)],.15)
write('miss',[(0,185,.13,.28),(.07,155,.14,.25)],.23)
write('complete',[(0,523.25,.3,.3),(.1,659.25,.3,.3),(.2,783.99,.35,.3),(.32,1046.5,.5,.3)],.85)
