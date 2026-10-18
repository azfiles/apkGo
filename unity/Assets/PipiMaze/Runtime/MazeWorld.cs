using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace PipiMaze
{
    [Serializable] public class ColliderData { public Vector3 size,position; }
    [Serializable] public class ModelData { public string name;public ColliderData[] colliders; }
    [Serializable] public class ModelCatalog { public ModelData[] assets; }
    [Serializable] public class Progress
    {
        public string level;public int[] lit,stars;public Vector3 safe;public float elapsed;public int jumps,rescues;
    }
    public sealed class MazeWorld : MonoBehaviour
    {
        public Level Level {get;private set;} public int Chapter {get;private set;}
        public Transform Player {get;private set;}public Camera Camera {get;private set;}
        public readonly HashSet<int> Lit=new HashSet<int>(),Stars=new HashSet<int>();
        public bool Active,Home=true,Completed,Muted;
        public bool LowQuality {get;private set;}
        public Vector2 Move;public bool Sprint;public float Energy=1,Elapsed,Yaw,Pitch=24;
        public int Jumps,Rescues;public Action Changed,Escaped;public Action<string> Notice;
        public Vector3 Velocity=>controller&&controller.enabled?controller.velocity:Vector3.zero;
        public int NearbyBeacon=-1;public bool NearbyGate;public float PreviewYaw=155;
        GameObject geometry,dynamicRoot;CharacterController controller;Transform avatar,stage,gate,portal;
        Transform[] stars,beacons;float[] starHeights;BrownMotion motion;Vector3 velocity,safe;float phase,coyote,jumpBuffer,saveTimer,hintCooldown,hintTime,movedDistance;bool movementReported;
        Light sun;AudioSource audioSource,ambience;LineRenderer route;
        readonly Dictionary<string,GameObject> models=new Dictionary<string,GameObject>();
        readonly Dictionary<string,ModelData> catalog=new Dictionary<string,ModelData>();
        readonly Dictionary<Material,Material> occluders=new Dictionary<Material,Material>();
        readonly Dictionary<string,Material> colors=new Dictionary<string,Material>();
        readonly List<GameObject> sparks=new List<GameObject>();
        readonly List<Mesh> combinedMeshes=new List<Mesh>();
        sealed class Batch { public Material Material;public readonly List<CombineInstance> Parts=new List<CombineInstance>(); }
        const float Gravity=18,JumpSpeed=6.8f;
        public void Initialize()
        {
            Application.targetFrameRate=60;Screen.sleepTimeout=SleepTimeout.NeverSleep;
            RenderSettings.ambientMode=AmbientMode.Flat;RenderSettings.ambientLight=Hex("91b7a2")*.55f;
            RenderSettings.fog=true;RenderSettings.fogMode=FogMode.Linear;RenderSettings.fogStartDistance=42;RenderSettings.fogEndDistance=120;
            var lightObject=new GameObject("Warm sun");sun=lightObject.AddComponent<Light>();sun.type=LightType.Directional;sun.color=Hex("fff0d2");sun.intensity=.90f;lightObject.transform.rotation=Quaternion.Euler(48,-35,0);
            QualitySettings.vSyncCount=0;
            var cameraObject=new GameObject("Main Camera");Camera=cameraObject.AddComponent<Camera>();cameraObject.AddComponent<AudioListener>();cameraObject.tag="MainCamera";Camera.nearClipPlane=.15f;Camera.farClipPlane=170;Camera.fieldOfView=52;Camera.allowHDR=false;
            string device=(SystemInfo.deviceModel+" "+SystemInfo.graphicsDeviceName).ToLowerInvariant();
            bool software=device.Contains("android sdk")||device.Contains("sdk_gphone")||device.Contains("swiftshader")||device.Contains("llvmpipe");
            int preference=PlayerPrefs.GetInt("pipi.quality",-1);SetQuality(preference<0?software:preference==0);
            audioSource=gameObject.AddComponent<AudioSource>();ambience=gameObject.AddComponent<AudioSource>();ambience.clip=Resources.Load<AudioClip>("Audio/ambience");ambience.loop=true;ambience.volume=.23f;ambience.Play();
            foreach(var data in JsonUtility.FromJson<ModelCatalog>(Resources.Load<TextAsset>("catalog").text).assets)catalog[data.name]=data;
        }
        public void SetQuality(bool low)
        {
            LowQuality=low;sun.shadows=low?LightShadows.None:LightShadows.Hard;
            QualitySettings.shadows=low?ShadowQuality.Disable:ShadowQuality.HardOnly;QualitySettings.shadowDistance=25;QualitySettings.shadowCascades=0;
            QualitySettings.shadowResolution=ShadowResolution.Medium;QualitySettings.antiAliasing=low?0:2;QualitySettings.pixelLightCount=1;
            QualitySettings.realtimeReflectionProbes=false;Camera.allowMSAA=!low;
            Debug.Log("PIPI_QUALITY: "+(low?"low":"standard"));
        }
        public Vector3 At(Cell c,float height=0)=>new Vector3((c.x-Level.Width/2)*4,height,-(c.y-Level.Width/2)*4);
        public Cell CellAt(Vector3 p)=>new Cell(Mathf.RoundToInt(p.x/4)+Level.Width/2,Mathf.RoundToInt(-p.z/4)+Level.Width/2);
        public static Color Hex(string value){Color c;return ColorUtility.TryParseHtmlString("#"+value,out c)?c:Color.white;}
        Material ColorMaterial(string color,bool glow=false)
        {
            string key=color+(glow?"glow":"");if(colors.TryGetValue(key,out var found))return found;
            var material=new Material(Shader.Find("Pipi/Soft")){color=Hex(color),enableInstancing=true};if(glow)material.SetColor("_Emission",Hex(color)*.65f);colors[key]=material;return material;
        }
        GameObject Box(Vector3 size,Vector3 position,string color,Transform parent,bool collision=true)
        {
            var go=GameObject.CreatePrimitive(PrimitiveType.Cube);go.transform.SetParent(parent,false);go.transform.localPosition=position;go.transform.localScale=size;go.GetComponent<Renderer>().sharedMaterial=ColorMaterial(color);if(!collision)DestroyImmediate(go.GetComponent<Collider>());return go;
        }
        GameObject Model(string name,Transform parent,Vector3 position,bool collision=false,float angle=0,float scale=1,bool cutaway=false)
        {
            if(!models.TryGetValue(name,out var template)){template=Resources.Load<GameObject>("Models/"+name);if(!template)throw new InvalidOperationException("Missing model: "+name);models[name]=template;}
            GameObject go=Instantiate(template,parent);go.name=name;go.transform.localPosition=position;go.transform.localRotation=Quaternion.Euler(0,-angle,0);go.transform.localScale=Vector3.one*scale;
            if(collision && catalog.TryGetValue(name,out var definition))foreach(var c in definition.colliders){var box=go.AddComponent<BoxCollider>();box.size=c.size;box.center=new Vector3(c.position.x,c.position.y,-c.position.z);}
            if(cutaway)foreach(var renderer in go.GetComponentsInChildren<MeshRenderer>())
            {
                Material[] ms=renderer.sharedMaterials;for(int i=0;i<ms.Length;i++){if(!occluders.TryGetValue(ms[i],out var m)){m=new Material(ms[i]);m.SetFloat("_Occluder",1);occluders[ms[i]]=m;}ms[i]=m;}renderer.sharedMaterials=ms;
            }
            return go;
        }
        public void Build(int chapter)
        {
            Active=false;Chapter=Mathf.Clamp(chapter,0,Level.Ids.Length-1);Level=JsonUtility.FromJson<Level>(Resources.Load<TextAsset>("Levels/"+Level.Ids[Chapter]).text);Level.Validate();
            if(geometry)DestroyImmediate(geometry);if(dynamicRoot)DestroyImmediate(dynamicRoot);foreach(var mesh in combinedMeshes)if(mesh)DestroyImmediate(mesh);combinedMeshes.Clear();
            geometry=new GameObject("Authored architecture");dynamicRoot=new GameObject("Gameplay");Lit.Clear();Stars.Clear();sparks.Clear();
            Elapsed=0;Energy=1;Jumps=Rescues=0;Completed=false;phase=coyote=jumpBuffer=0;Yaw=0;Pitch=24;hintCooldown=hintTime=0;movedDistance=0;movementReported=false;
            Camera.backgroundColor=Hex(Level.environment?.background??"b9dfe0");RenderSettings.fogColor=Hex(Level.environment?.fog??"c7e2d7");
            var rng=new System.Random(Level.seed);string[] floors={"d9dfbe","e0e3c7","d4dbb9","e5e5c9"};
            for(int z=0;z<Level.Width;z++)for(int x=0;x<Level.Width;x++)
            {
                Cell cell=new Cell(x,z);Vector3 p=At(cell);char surface=Level.Surface(cell);Challenge challenge=Level.Hazard(cell);
                if(Level.Open(cell))
                {
                    if(challenge!=null&&challenge.kind=="gap")BuildGap(p,challenge);
                    else
                    {
                        var tile=Model(surface=='='?"garden_bridge":"courtyard_tile",geometry.transform,p,true,surface=='='?Level.bridge_rotation_y:0);
                        string tint=floors[rng.Next(floors.Length)];if(Level.regions!=null)foreach(var region in Level.regions){var b=region.bounds;if(x>=b[0]&&z>=b[1]&&x<=b[2]&&z<=b[3]){tint=region.floor;break;}}
                        if(surface!='=')foreach(var t in tile.GetComponentsInChildren<Transform>())if(t.name.StartsWith("TileTop"))foreach(var r in t.GetComponentsInChildren<Renderer>())r.sharedMaterial=ColorMaterial(tint);
                        if(challenge!=null)BuildHurdle(p,challenge);
                        if(challenge==null&&rng.NextDouble()<.24)Model("grass",geometry.transform,p+new Vector3(1.5f,.02f,-1.5f),false,rng.Next(360));
                        if(challenge==null&&rng.NextDouble()<.08)Model("lantern",geometry.transform,p+new Vector3(1.4f,0,-1.4f));
                    }
                }
                else if(surface=='~')Box(new Vector3(3.98f,.08f,3.98f),p+Vector3.down*1.1f,Level.environment?.water??"69bfc9",geometry.transform,false);
                else
                {
                    Model("wall_"+rng.Next(3),geometry.transform,p,true,0,1,true);
                    if((x==0||z==0||x==Level.Width-1||z==Level.Width-1)&&(x+z)%3==0)Model("tree_"+(Chapter%2),geometry.transform,p+Vector3.up*2.25f,false,rng.Next(360),1.1f,true);
                }
            }
            if(Level.scenery!=null)foreach(var item in Level.scenery)Model(item.asset,geometry.transform,new Vector3(item.position.x,item.position.y,-item.position.z),item.collisions,item.rotation_y,item.scale,true);
            for(int i=0;i<12;i++)
            {
                float angle=i*Mathf.PI/6;Vector3 p=new Vector3(Mathf.Cos(angle)*85,-6,Mathf.Sin(angle)*85);var hill=GameObject.CreatePrimitive(PrimitiveType.Sphere);hill.transform.SetParent(geometry.transform,false);hill.transform.position=p;hill.transform.localScale=new Vector3(34,25,38);hill.GetComponent<Renderer>().sharedMaterial=ColorMaterial(i%2==0?"a9d1b4":"94c8b7");DestroyImmediate(hill.GetComponent<Collider>());
                if(i%2==0)Model("cloud",geometry.transform,p+Vector3.up*27,false,-angle*Mathf.Rad2Deg,3);
            }
            beacons=new Transform[3];for(int i=0;i<3;i++){Vector3 p=At(Level.beacons[i])+new Vector3(1.05f,0,1.05f);Model("beacon",geometry.transform,p,true);beacons[i]=Model("crystal",dynamicRoot.transform,p+Vector3.up*1.85f).transform;}
            stars=new Transform[Level.motes.Length];starHeights=new float[stars.Length];
            for(int i=0;i<stars.Length;i++){starHeights[i]=Level.Elevated(i)?2.05f:.85f;stars[i]=Model("star",dynamicRoot.transform,At(Level.motes[i],starHeights[i])).transform;}
            gate=Model("portal",geometry.transform,At(Level.goal)).transform;
            var orb=GameObject.CreatePrimitive(PrimitiveType.Sphere);orb.name="Awakened portal";orb.transform.SetParent(dynamicRoot.transform,false);orb.transform.position=gate.position+Vector3.up*1.7f;orb.transform.localScale=new Vector3(1.9f,2.8f,.1f);DestroyImmediate(orb.GetComponent<Collider>());orb.GetComponent<Renderer>().sharedMaterial=ColorMaterial("8ce8dd",true);portal=orb.transform;portal.gameObject.SetActive(false);
            var player=new GameObject("Brown");player.transform.SetParent(dynamicRoot.transform,false);Player=player.transform;
            controller=player.AddComponent<CharacterController>();controller.height=1.65f;controller.radius=.30f;controller.center=Vector3.up*.83f;controller.stepOffset=.22f;controller.skinWidth=.025f;controller.minMoveDistance=0;
            avatar=Model("brown",Player,Vector3.zero).transform;avatar.localRotation=Quaternion.Euler(0,180,0);motion=new BrownMotion(avatar);
            var podium=GameObject.CreatePrimitive(PrimitiveType.Cylinder);podium.transform.SetParent(dynamicRoot.transform,false);podium.transform.position=At(Level.start)+new Vector3(4,-.07f,4);podium.transform.localScale=new Vector3(2,.06f,2);podium.GetComponent<Renderer>().sharedMaterial=ColorMaterial("f6e5b9");DestroyImmediate(podium.GetComponent<Collider>());stage=podium.transform;
            var routeObject=new GameObject("Golden route");routeObject.transform.SetParent(dynamicRoot.transform);route=routeObject.AddComponent<LineRenderer>();route.sharedMaterial=ColorMaterial("ffe6a4",true);route.widthMultiplier=.11f;route.positionCount=0;route.numCornerVertices=4;
            safe=At(Level.start,.08f);Restore();SetHome(true);
            BatchGeometry();
            Debug.Log("PIPI_EVENT: WORLD_READY "+Level.id);Changed?.Invoke();
        }
        void BatchGeometry()
        {
            // Combine by material and 16-meter region. Keep authored colliders in
            // place while reducing thousands of small renderers to bounded groups.
            var groups=new Dictionary<string,Batch>();int sourceCount=0;
            foreach(var filter in geometry.GetComponentsInChildren<MeshFilter>())
            {
                var renderer=filter.GetComponent<MeshRenderer>();var mesh=filter.sharedMesh;
                if(!renderer||!renderer.enabled||!mesh||!mesh.isReadable)continue;
                var materials=renderer.sharedMaterials;if(materials.Length==0)continue;
                Vector3 p=filter.transform.position;int x=Mathf.FloorToInt(p.x/16),z=Mathf.FloorToInt(p.z/16);
                for(int s=0;s<mesh.subMeshCount;s++)
                {
                    Material material=materials[Mathf.Min(s,materials.Length-1)];if(!material)continue;
                    string key=material.GetInstanceID()+":"+x+":"+z;
                    if(!groups.TryGetValue(key,out var batch)){batch=new Batch{Material=material};groups[key]=batch;}
                    batch.Parts.Add(new CombineInstance{mesh=mesh,subMeshIndex=s,transform=geometry.transform.worldToLocalMatrix*filter.transform.localToWorldMatrix});
                }
                renderer.enabled=false;sourceCount++;
            }
            foreach(var group in groups.Values)
            {
                var mesh=new Mesh{name="Batched architecture",indexFormat=IndexFormat.UInt32};mesh.CombineMeshes(group.Parts.ToArray(),true,true);mesh.RecalculateBounds();combinedMeshes.Add(mesh);
                var go=new GameObject("Architecture group");go.transform.SetParent(geometry.transform,false);go.AddComponent<MeshFilter>().sharedMesh=mesh;
                var renderer=go.AddComponent<MeshRenderer>();renderer.sharedMaterial=group.Material;renderer.lightProbeUsage=LightProbeUsage.Off;renderer.reflectionProbeUsage=ReflectionProbeUsage.Off;
            }
            Debug.Log("PIPI_BATCH: "+sourceCount+" source renderers -> "+groups.Count+" material/region groups");
        }
        void BuildHurdle(Vector3 p,Challenge c)
        {
            bool alongX=c.axis.x!=0;var hurdle=Model("hurdle",geometry.transform,p,false,alongX?90:0);hurdle.transform.localScale=new Vector3(1,c.height/.65f,1);
            var collider=hurdle.AddComponent<BoxCollider>();collider.size=new Vector3(4,.65f,.65f);collider.center=new Vector3(0,.325f,0);
        }
        void BuildGap(Vector3 p,Challenge c)
        {
            bool alongX=c.axis.x!=0;float length=(4-c.span)/2;var axis=new Vector3(c.axis.x,0,-c.axis.y);
            foreach(int side in new[]{-1,1})Box(alongX?new Vector3(length,.6f,4):new Vector3(4,.6f,length),p+axis*side*(4+c.span)/4+Vector3.down*.32f,"d8dfbf",geometry.transform);
            Box(alongX?new Vector3(c.span,.05f,4):new Vector3(4,.05f,c.span),p+Vector3.down*1.5f,"69bfc9",geometry.transform,false);
        }
        void Teleport(Vector3 p){controller.enabled=false;Player.position=p;controller.enabled=!Home;velocity=Vector3.zero;}
        public void SetHome(bool home)
        {
            Home=home;Active=!home;Move=Vector2.zero;Sprint=false;controller.enabled=false;Player.position=home?stage.position+Vector3.up*.07f:safe;controller.enabled=!home;velocity=Vector3.zero;
            stage.gameObject.SetActive(home);PreviewYaw=155;JumpReset();UpdateCamera(1);Debug.Log("PIPI_EVENT: "+(home?"HOME":"PLAY"));
        }
        void JumpReset(){jumpBuffer=coyote=0;}
        public void Jump(){if(Active){jumpBuffer=.12f;}}
        public void SetPaused(bool paused){Active=!paused&&!Home&&!Completed;Move=Vector2.zero;Sprint=false;if(paused)Save();Debug.Log("PIPI_EVENT: "+(paused?"PAUSE":"RESUME"));}
        public void Sound(string name){if(!Muted){var clip=Resources.Load<AudioClip>("Audio/"+name);if(clip)audioSource.PlayOneShot(clip,.65f);}}
        public void SetMute(bool muted){Muted=muted;ambience.mute=muted;}
        public void Rescue(){Teleport(safe);Move=Vector2.zero;Rescues++;JumpReset();motion.Emote("Surprise");Notice?.Invoke("已回到安全落脚点 · 星星与灯塔进度保留");}
        public void Interact()
        {
            if(!Active)return;
            if(NearbyBeacon>=0){int i=NearbyBeacon;Lit.Add(i);beacons[i].localScale=Vector3.one*.65f;Burst(beacons[i].position,24);Sound("beacon");motion.Emote("Joy",2);portal.gameObject.SetActive(Lit.Count==3);Notice?.Invoke(Lit.Count==3?"三座灯塔已点亮 · 出口苏醒了":"灯塔已点亮  "+Lit.Count+" / 3");Debug.Log("PIPI_EVENT: BEACON "+Lit.Count);Save();Changed?.Invoke();}
            else if(NearbyGate){if(Lit.Count==3){Active=false;Completed=true;Sound("win");motion.Emote("Joy",999);Save();Escaped?.Invoke();Debug.Log("PIPI_EVENT: COMPLETE");}else Notice?.Invoke("还需要点亮 "+(3-Lit.Count)+" 座灯塔");}
            else Notice?.Invoke("靠近灯塔或出口后互动");
        }
        public void Hint()
        {
            if(!Active)return;if(hintCooldown>0){Notice?.Invoke("引路灯正在充能");return;}
            Cell from=CellAt(Player.position),target=Level.goal;int best=int.MaxValue;
            for(int i=0;i<3;i++)if(!Lit.Contains(i)){int distance=Level.Path(from,Level.beacons[i]).Count;if(distance<best){best=distance;target=Level.beacons[i];}}
            var cells=Level.Path(from,target);int count=Mathf.Min(cells.Count,7);route.positionCount=count+1;route.SetPosition(0,Player.position+Vector3.up*.08f);for(int i=0;i<count;i++)route.SetPosition(i+1,At(cells[i],.08f));hintTime=8;hintCooldown=13;Sound("hint");Notice?.Invoke("跟随金色光迹 · 石栏与断桥需要跳跃");Debug.Log("PIPI_EVENT: HINT");
        }
        void Update()
        {
            if(!Player)return;float dt=Mathf.Min(Time.deltaTime,.1f);ambience.mute=Muted;
            if(Active)
            {
                Elapsed+=Time.unscaledDeltaTime;hintCooldown=Mathf.Max(0,hintCooldown-dt);hintTime=Mathf.Max(0,hintTime-dt);route.enabled=hintTime>0;
                Vector2 input=Vector2.ClampMagnitude(Move,1);if(input.magnitude<.12f)input=Vector2.zero;
                float angle=Yaw*Mathf.Deg2Rad;var forward=new Vector3(Mathf.Sin(angle),0,Mathf.Cos(angle));var right=new Vector3(forward.z,0,-forward.x);var direction=right*input.x+forward*input.y;
                bool running=Sprint&&Energy>.06f&&direction.magnitude>.2f;Energy=Mathf.Clamp01(Energy+dt*(running?-.25f:.19f));
                Vector3 target=direction*(running?5.5f:3.25f);velocity.x=Mathf.MoveTowards(velocity.x,target.x,dt*18);velocity.z=Mathf.MoveTowards(velocity.z,target.z,dt*18);
                bool grounded=controller.isGrounded;coyote=grounded?.10f:Mathf.Max(0,coyote-dt);jumpBuffer=Mathf.Max(0,jumpBuffer-dt);if(grounded&&velocity.y<0)velocity.y=-1.5f;
                if(jumpBuffer>0&&coyote>0){velocity.y=JumpSpeed;coyote=jumpBuffer=0;Jumps++;Sound("jump");Debug.Log("PIPI_EVENT: JUMP");}
                velocity.y-=Gravity*dt;Vector3 before=Player.position;controller.Move(velocity*dt);
                if(Player.position.y< -2.5f)Rescue();Vector3 traveled=Player.position-before;traveled.y=0;phase+=traveled.magnitude*3.3f;movedDistance+=traveled.magnitude;
                if(!movementReported&&movedDistance>1){movementReported=true;Debug.Log("PIPI_EVENT: MOVED");}
                if(traveled.magnitude>.001f){float facing=Mathf.Atan2(traveled.x,traveled.z)*Mathf.Rad2Deg+180;avatar.rotation=Quaternion.Slerp(avatar.rotation,Quaternion.Euler(0,facing,0),dt*12);}
                Cell cell=CellAt(Player.position);if(controller.isGrounded&&Mathf.Abs(Player.position.y)<.12f&&Level.Open(cell)&&Level.Hazard(cell)==null&&Vector3.Distance(Player.position,At(cell))<.7f)safe=At(cell,.08f);
                NearbyBeacon=-1;for(int i=0;i<3;i++){Vector3 delta=Player.position-beacons[i].position;delta.y=0;if(!Lit.Contains(i)&&delta.magnitude<1.65f&&controller.isGrounded)NearbyBeacon=i;}
                NearbyGate=Vector3.Distance(Player.position,gate.position)<1.8f&&controller.isGrounded;
                for(int i=0;i<stars.Length;i++)if(!Stars.Contains(i)&&Vector3.Distance(Player.position+Vector3.up*.85f,stars[i].position)<.72f){Stars.Add(i);stars[i].gameObject.SetActive(false);Burst(stars[i].position,12);Sound("mote");motion.Emote("Joy");Changed?.Invoke();Debug.Log("PIPI_EVENT: STAR "+Stars.Count);Save();}
                saveTimer+=dt;if(saveTimer>5){saveTimer=0;Save();}
            }
            if(Active||Home||Completed)
            {
                for(int i=0;i<stars.Length;i++)if(stars[i].gameObject.activeSelf){var p=stars[i].position;p.y=starHeights[i]+Mathf.Sin(Time.time*2.3f+i)*.1f;stars[i].position=p;stars[i].rotation=Quaternion.Euler(0,Time.time*38+i*40,Mathf.Sin(Time.time*1.8f+i)*6);}
                for(int i=0;i<3;i++){var p=beacons[i].position;p.y=1.85f+Mathf.Sin(Time.time*2+i)*.13f;beacons[i].position=p;beacons[i].Rotate(0,dt*40,0);}
                motion.Tick(dt,Active?controller.velocity:Vector3.zero,Home||controller.isGrounded,phase,Home||Completed);
            }
            UpdateCamera(dt);Shader.SetGlobalVector("_Hero",new Vector4(Player.position.x,Player.position.y+1,Player.position.z,1));
            for(int i=sparks.Count-1;i>=0;i--){if(!sparks[i]){sparks.RemoveAt(i);continue;}sparks[i].transform.position+=Vector3.up*dt*.7f;sparks[i].transform.Rotate(55*dt,80*dt,0);}
        }
        void UpdateCamera(float dt)
        {
            Vector3 focus=Player.position+Vector3.up*(Home?1.05f:1.35f);float angle=(Home?PreviewYaw:Yaw)*Mathf.Deg2Rad,pitch=(Home?12:Pitch)*Mathf.Deg2Rad,distance=Home?5.4f:Sprint?7.4f:6.8f;
            Vector3 offset=new Vector3(-Mathf.Sin(angle)*Mathf.Cos(pitch),Mathf.Sin(pitch),-Mathf.Cos(angle)*Mathf.Cos(pitch))*distance;
            if(Home){Vector3 right=new Vector3(Mathf.Cos(angle),0,-Mathf.Sin(angle));focus-=right*1.12f;}
            Vector3 desired=focus+offset;if(!Home)desired.y=Mathf.Max(desired.y,3.1f);Camera.transform.position=Vector3.Lerp(Camera.transform.position,desired,1-Mathf.Exp(-dt*11));Camera.transform.LookAt(focus);Camera.fieldOfView=Mathf.Lerp(Camera.fieldOfView,Home?42:52,dt*4);
        }
        void Burst(Vector3 at,int count)
        {
            for(int i=0;i<count;i++){var go=Box(Vector3.one*.055f,at+UnityEngine.Random.insideUnitSphere*.4f,"ffda8a",dynamicRoot.transform,false);sparks.Add(go);Destroy(go,.6f+UnityEngine.Random.value*.35f);}
        }
        public void Save()
        {
            if(Level==null||Home)return;var lit=new int[Lit.Count];Lit.CopyTo(lit);var collected=new int[Stars.Count];Stars.CopyTo(collected);
            var data=new Progress{level=Level.id,lit=lit,stars=collected,safe=safe,elapsed=Elapsed,jumps=Jumps,rescues=Rescues};PlayerPrefs.SetString("pipi.unity."+Level.id,JsonUtility.ToJson(data));PlayerPrefs.SetInt("pipi.chapter",Chapter);PlayerPrefs.Save();
        }
        void Restore()
        {
            string raw=PlayerPrefs.GetString("pipi.unity."+Level.id,"");if(raw.Length==0)return;
            try{var p=JsonUtility.FromJson<Progress>(raw);if(p.level!=Level.id)return;Cell c=CellAt(p.safe);if(Level.Open(c)&&Level.Hazard(c)==null)safe=At(c,.08f);Elapsed=Mathf.Max(0,p.elapsed);Jumps=Mathf.Max(0,p.jumps);Rescues=Mathf.Max(0,p.rescues);
                if(p.lit!=null)foreach(int i in p.lit)if(i>=0&&i<3){Lit.Add(i);beacons[i].localScale=Vector3.one*.65f;}
                if(p.stars!=null)foreach(int i in p.stars)if(i>=0&&i<stars.Length){Stars.Add(i);stars[i].gameObject.SetActive(false);}portal.gameObject.SetActive(Lit.Count==3);
            }catch(Exception e){Debug.LogWarning("Ignored invalid preview save: "+e.GetType().Name);}
        }
        public void Restart(){PlayerPrefs.DeleteKey("pipi.unity."+Level.id);Build(Chapter);SetHome(false);}
        void OnApplicationPause(bool pause){if(pause&&Active){SetPaused(true);Notice?.Invoke("已暂停");}}
        void OnApplicationQuit(){Save();}
    }
}
