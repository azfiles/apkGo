using System.Collections.Generic;
using UnityEngine;

namespace PipiMaze
{
    public sealed class BrownMotion
    {
        readonly Dictionary<string,Transform> parts=new Dictionary<string,Transform>();
        readonly Dictionary<string,Quaternion> rest=new Dictionary<string,Quaternion>();
        readonly Dictionary<string,Transform> faces=new Dictionary<string,Transform>();
        float stride,air,emoteUntil; string emote="Smile";
        Transform body;Vector3 bodyOrigin;
        public BrownMotion(Transform avatar)
        {
            foreach(var t in avatar.GetComponentsInChildren<Transform>(true)){parts[t.name]=t;rest[t.name]=t.localRotation;if(t.name.StartsWith("Face"))faces[t.name]=t;}
            if(parts.TryGetValue("Body",out body))bodyOrigin=body.localPosition;
        }
        public void Emote(string name,float duration=1.5f){emote=name;emoteUntil=Time.unscaledTime+duration;}
        void Pose(string key,Vector3 radians,float blend)
        {
            if(parts.TryGetValue(key,out var t))t.localRotation=Quaternion.Slerp(t.localRotation,rest[key]*Quaternion.Euler(new Vector3(-radians.x,-radians.y,radians.z)*Mathf.Rad2Deg),blend);
        }
        public void Tick(float dt,Vector3 velocity,bool grounded,float phase,bool preview)
        {
            float blend=1-Mathf.Exp(-dt*14),speed=new Vector2(velocity.x,velocity.z).magnitude;
            float run=Mathf.Clamp01((speed-3)/2.5f);stride=Mathf.Lerp(stride,preview?0:Mathf.Clamp01(speed/2),blend);air=Mathf.Lerp(air,grounded||preview?0:1,blend);
            float wave=Mathf.Sin(phase)*stride,rise=Mathf.Clamp01((velocity.y+2)/7),amplitude=Mathf.Lerp(.46f,.78f,run);
            for(int i=0;i<2;i++)
            {
                string side=i==0?"L":"R";float sign=i==0?-1:1,gait=wave*sign;
                Pose("Leg"+side,new Vector3(Mathf.Lerp(gait*amplitude,Mathf.Lerp(-.10f,-.38f,rise)+sign*.09f,air),0,0),blend);
                Pose("Knee"+side,new Vector3(Mathf.Lerp(Mathf.Max(0,-gait)*Mathf.Lerp(.62f,1.05f,run),Mathf.Lerp(.25f,.82f,rise),air),0,0),blend);
                Pose("Arm"+side,new Vector3(Mathf.Lerp(-gait*amplitude*.85f,Mathf.Lerp(-.20f,-.85f,rise),air),0,sign*(.08f+air*.2f)),blend);
                Pose("Elbow"+side,new Vector3(Mathf.Lerp(-.12f-run*.48f,-.45f,air),0,0),blend);
                Pose("Ear"+side,new Vector3(Mathf.Sin(phase-.4f)*stride*.06f+air*.12f,0,sign*(Mathf.Sin(Time.time*1.8f)*.02f+wave*.07f)),blend);
            }
            Pose("Torso",new Vector3(stride*(.04f+run*.08f)+air*.03f,0,-wave*.025f),blend);
            Pose("Head",new Vector3(-stride*.025f-air*.04f,0,Mathf.Sin(Time.time*.8f)*.018f-wave*.012f),blend);
            Pose("Satchel",new Vector3(Mathf.Sin(phase-.65f)*stride*.12f+air*.12f,0,-wave*.055f),blend);
            if(body)body.localPosition=bodyOrigin+Vector3.up*Mathf.Lerp(Mathf.Sin(Time.time*2)*.008f,Mathf.Abs(Mathf.Cos(phase))*.035f,stride)*(1-air);
            string face=Time.unscaledTime<emoteUntil?emote:air>.4f?"Surprise":run>.3f?"Focus":preview&&Time.time%10>8.5f?"Joy":"Smile";
            foreach(var f in faces)f.Value.gameObject.SetActive(f.Key=="Face"+face);
            float blink=Time.time%3.9f;float eyeScale=blink<.18f?1-.9f*Mathf.Sin(blink/.18f*Mathf.PI):1;
            foreach(string side in new[]{"L","R"})if(parts.TryGetValue("Eye"+side,out var eye)){eye.gameObject.SetActive(face!="Joy");eye.localScale=new Vector3(1,eyeScale,1);}
        }
    }
}
