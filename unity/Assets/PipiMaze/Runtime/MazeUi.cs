using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace PipiMaze
{
    public sealed class MazeUi : MonoBehaviour
    {
        MazeWorld world;Canvas canvas;RectTransform safe,root;Font font;
        Text status,timeLabel,fps,toast,interaction;GameObject mapPanel;Texture2D mapTexture;
        Vector2 stick;float toastUntil,mapTimer,fpsTimer,frameTime;bool paused,mapOpen,showFps=true;int page=-1;
        Color ink=MazeWorld.Hex("244e43"),cream=MazeWorld.Hex("fff6de"),gold=MazeWorld.Hex("f4c96a"),green=MazeWorld.Hex("315c4f");
        public void Initialize(MazeWorld value)
        {
            world=value;font=Resources.Load<Font>("Fonts/PipiSans");if(!font)font=Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            var go=new GameObject("Touch interface",typeof(RectTransform),typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster));canvas=go.GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceOverlay;
            var scaler=go.GetComponent<CanvasScaler>();scaler.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=new Vector2(1280,720);scaler.screenMatchMode=CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;scaler.matchWidthOrHeight=.5f;
            safe=new GameObject("Safe area",typeof(RectTransform)).GetComponent<RectTransform>();safe.SetParent(canvas.transform,false);safe.anchorMin=Vector2.zero;safe.anchorMax=Vector2.one;safe.offsetMin=safe.offsetMax=Vector2.zero;
            if(!FindObjectOfType<EventSystem>())new GameObject("Input events",typeof(EventSystem),typeof(StandaloneInputModule));
            world.Notice=Notify;world.Changed=Refresh;world.Escaped=ShowComplete;world.SetMute(PlayerPrefs.GetInt("pipi.mute",0)==1);showFps=PlayerPrefs.GetInt("pipi.fps",1)==1;
        }
        RectTransform Rect(Transform parent,string name,float x,float y,float w,float h)
        {
            var r=new GameObject(name,typeof(RectTransform)).GetComponent<RectTransform>();r.SetParent(parent,false);r.anchorMin=r.anchorMax=new Vector2(0,1);r.pivot=new Vector2(0,1);r.anchoredPosition=new Vector2(x,-y);r.sizeDelta=new Vector2(w,h);return r;
        }
        Image Panel(Transform parent,float x,float y,float w,float h,Color color)
        {var r=Rect(parent,"Panel",x,y,w,h);var image=r.gameObject.AddComponent<Image>();image.color=color;return image;}
        Text Label(Transform parent,string text,float x,float y,float w,float h,int size,Color color,TextAnchor align=TextAnchor.MiddleLeft)
        {
            var r=Rect(parent,"Text",x,y,w,h);var t=r.gameObject.AddComponent<Text>();t.font=font;t.text=text;t.fontSize=size;t.color=color;t.alignment=align;t.raycastTarget=false;t.horizontalOverflow=HorizontalWrapMode.Wrap;t.verticalOverflow=VerticalWrapMode.Truncate;return t;
        }
        Button Button(Transform parent,string text,float x,float y,float w,float h,Action action,bool primary=false)
        {
            var image=Panel(parent,x,y,w,h,primary?green:new Color(cream.r,cream.g,cream.b,.95f));var b=image.gameObject.AddComponent<Button>();var colors=b.colors;colors.highlightedColor=new Color(.86f,.94f,.86f);colors.pressedColor=new Color(.72f,.84f,.76f);b.colors=colors;
            Label(image.transform,text,4,0,w-8,h,primary?23:19,primary?cream:ink,TextAnchor.MiddleCenter);b.onClick.AddListener(()=>{world.Sound("hint");action();});return b;
        }
        void Begin(int newPage)
        {
            if(root){root.gameObject.SetActive(false);Destroy(root.gameObject);}stick=Vector2.zero;world.Move=Vector2.zero;world.Sprint=false;page=newPage;toast=null;status=null;timeLabel=null;interaction=null;fps=null;mapPanel=null;mapOpen=false;
            var rect=safe.rect;float width=rect.width>0?rect.width:1280,height=rect.height>0?rect.height:720;
            root=Rect(safe,"Page",(width-1280)/2,(height-720)/2,1280,720);
            var look=Panel(root,525,0,755,720,new Color(0,0,0,0));var pointer=look.gameObject.AddComponent<PointerControl>();pointer.Drag=e=>{if(world.Home)world.PreviewYaw+=e.delta.x/canvas.scaleFactor*.30f;else if(world.Active){world.Yaw+=e.delta.x/canvas.scaleFactor*.19f;world.Pitch=Mathf.Clamp(world.Pitch-e.delta.y/canvas.scaleFactor*.14f,9,58);}};
        }
        public void ShowHome()
        {
            paused=false;world.SetHome(true);Begin(0);
            Label(root,"PIPI MAZE   /   UNITY PREVIEW",48,28,700,30,17,ink);
            var card=Panel(root,48,83,455,588,new Color(cream.r,cream.g,cream.b,.97f));
            Label(card.transform,"灯火遗迹",26,18,400,65,44,ink);
            Label(card.transform,"带着布朗，循着微光找到归途",28,84,400,35,20,ink);
            Label(card.transform,"选择章节",28,138,220,30,16,green);
            string[] titles={"01   初光庭院","02   回声回廊","03   星眠深境","04   星桥水庭"};
            for(int i=0;i<4;i++){int chapter=i;var b=Button(card.transform,titles[i]+(world.Chapter==i?"   ·":""),28,179+i*60,399,50,()=>{world.Save();world.Build(chapter);ShowHome();},world.Chapter==i);}
            Button(card.transform,world.Lit.Count>0||world.Stars.Count>0?"继续探索   →":"开始探索   →",28,446,399,59,()=>{world.SetHome(false);ShowGame();},true);
            Label(card.transform,"Unity 试玩版 0.1.0 · 四章均可体验",28,524,399,32,15,ink);
            Label(root,"拖动右侧 · 360° 查看布朗",688,636,500,35,18,ink,TextAnchor.MiddleCenter);
            AddOptions(root,928,28);
        }
        void AddOptions(Transform parent,float x,float y)
        {
            Button(parent,world.Muted?"声音：关":"声音：开",x,y,132,38,()=>{world.SetMute(!world.Muted);PlayerPrefs.SetInt("pipi.mute",world.Muted?1:0);Reopen();});
            Button(parent,showFps?"FPS：开":"FPS：关",x+145,y,110,38,()=>{showFps=!showFps;PlayerPrefs.SetInt("pipi.fps",showFps?1:0);Reopen();});
            fps=Label(parent,"",x,y+43,255,25,14,ink,TextAnchor.MiddleRight);
        }
        void Reopen(){if(world.Home)ShowHome();else if(paused)ShowPause();else if(world.Completed)ShowComplete();else ShowGame();}
        public void ShowGame()
        {
            paused=false;Begin(1);var top=Panel(root,24,22,400,88,new Color(cream.r,cream.g,cream.b,.95f));
            Label(top.transform,world.Level.title,18,4,360,35,25,ink);status=Label(top.transform,"",18,42,360,33,18,ink);
            timeLabel=Label(root,"",554,26,170,38,23,ink,TextAnchor.MiddleCenter);
            fps=Label(root,"",540,68,200,25,15,ink,TextAnchor.MiddleCenter);
            Button(root,"引路灯",844,25,116,45,world.Hint);Button(root,"地图",974,25,116,45,ToggleMap);Button(root,"暂停",1104,25,148,45,()=>{world.SetPaused(true);ShowPause();});
            var outer=Panel(root,55,495,176,176,new Color(cream.r,cream.g,cream.b,.55f));var knob=Panel(outer.transform,58,58,60,60,new Color(green.r,green.g,green.b,.85f));
            Label(outer.transform,"移动",36,128,104,35,17,ink,TextAnchor.MiddleCenter);
            var pointer=outer.gameObject.AddComponent<PointerControl>();Action<PointerEventData> move=e=>{Vector2 p;RectTransformUtility.ScreenPointToLocalPointInRectangle(outer.rectTransform,e.position,e.pressEventCamera,out p);Vector2 delta=p-new Vector2(88,-88);stick=Vector2.ClampMagnitude(delta/65,1);knob.rectTransform.anchoredPosition=new Vector2(58,-58)+stick*47;};pointer.Down=move;pointer.Drag=move;pointer.Up=e=>{stick=Vector2.zero;knob.rectTransform.anchoredPosition=new Vector2(58,-58);};
            Button(root,"跳跃",1104,469,125,93,world.Jump,true);
            var sprint=Button(root,"冲刺",946,582,118,87,()=>{},false);var held=sprint.gameObject.AddComponent<PointerControl>();held.Down=e=>{world.Sprint=true;Debug.Log("PIPI_EVENT: SPRINT");};held.Up=e=>world.Sprint=false;
            var interact=Button(root,"互动",1104,582,125,87,world.Interact,true);interaction=interact.GetComponentInChildren<Text>();
            Label(root,"左侧移动 · 右侧转镜头",450,659,390,32,17,ink,TextAnchor.MiddleCenter);
            toast=Label(root,"",280,415,720,60,22,ink,TextAnchor.MiddleCenter);
            var panel=Panel(root,920,97,322,350,new Color(cream.r,cream.g,cream.b,.97f));mapPanel=panel.gameObject;
            var mapRect=Rect(panel.transform,"Map",11,11,300,300);var image=mapRect.gameObject.AddComponent<RawImage>();mapTexture=new Texture2D(world.Level.Width,world.Level.Width,TextureFormat.RGBA32,false);mapTexture.filterMode=FilterMode.Point;image.texture=mapTexture;
            Label(panel.transform,"白：布朗  金：灯塔  青：出口",11,315,300,28,15,ink,TextAnchor.MiddleCenter);mapPanel.SetActive(false);Refresh();
        }
        void ToggleMap(){mapOpen=!mapOpen;mapPanel.SetActive(mapOpen);if(mapOpen){DrawMap();Debug.Log("PIPI_EVENT: MAP");}}
        void ShowPause()
        {
            paused=true;Begin(2);Panel(root,0,0,1280,720,new Color(.08f,.19f,.16f,.55f));var card=Panel(root,405,80,470,555,cream);
            Label(card.transform,"休息片刻",32,24,406,65,36,ink,TextAnchor.MiddleCenter);Label(card.transform,"进度已自动保存",32,95,406,35,18,green,TextAnchor.MiddleCenter);
            Button(card.transform,"继续探索",45,158,380,57,()=>{world.SetPaused(false);ShowGame();},true);
            Button(card.transform,"重新开始本章",45,232,380,57,()=>{world.Restart();ShowGame();});Button(card.transform,"返回章节",45,306,380,57,()=>{world.Save();ShowHome();});
            AddOptions(card.transform,96,407);
        }
        void ShowComplete()
        {
            paused=false;Begin(3);Panel(root,0,0,1280,720,new Color(.08f,.19f,.16f,.5f));var card=Panel(root,380,136,520,430,cream);
            Label(card.transform,"灯火再次亮起",30,23,460,70,37,ink,TextAnchor.MiddleCenter);
            Label(card.transform,"星星  "+world.Stars.Count+" / "+world.Level.motes.Length+"     灯塔  3 / 3",30,113,460,40,23,ink,TextAnchor.MiddleCenter);
            Label(card.transform,"用时 "+Format(world.Elapsed)+"    跳跃 "+world.Jumps,30,165,460,40,19,green,TextAnchor.MiddleCenter);
            Button(card.transform,world.Chapter<3?"下一章   →":"再次探索",60,235,400,60,()=>{world.Build((world.Chapter+1)%4);world.SetHome(false);ShowGame();},true);Button(card.transform,"返回章节",60,315,400,50,ShowHome);
        }
        void Notify(string message){if(toast){toast.text=message;toastUntil=Time.unscaledTime+3;}Debug.Log("PIPI_NOTICE: "+message);}
        void Refresh(){if(status)status.text="星星  "+world.Stars.Count+" / "+world.Level.motes.Length+"     灯塔  "+world.Lit.Count+" / 3";}
        string Format(float seconds)=>((int)seconds/60).ToString("00")+":"+((int)seconds%60).ToString("00");
        void DrawMap()
        {
            var level=world.Level;int n=level.Width;var pixels=new Color[n*n];for(int y=0;y<n;y++)for(int x=0;x<n;x++){char c=level.Surface(new Cell(x,y));pixels[y*n+x]=MazeWorld.Hex(c=='#'?"527264":c=='~'?"75beca":c=='='?"c9ad7c":"ecdfbd");}
            for(int i=0;i<3;i++){Cell c=level.beacons[i];pixels[c.y*n+c.x]=MazeWorld.Hex(world.Lit.Contains(i)?"6cdcc3":"e3a73b");}pixels[level.goal.y*n+level.goal.x]=MazeWorld.Hex("44bac1");Cell player=world.CellAt(world.Player.position);if(player.x>=0&&player.y>=0&&player.x<n&&player.y<n)pixels[player.y*n+player.x]=Color.white;mapTexture.SetPixels(pixels);mapTexture.Apply(false);
        }
        void Update()
        {
            if(!root||!world.Player)return;
            Rect area=Screen.safeArea;safe.anchorMin=new Vector2(area.xMin/Screen.width,area.yMin/Screen.height);safe.anchorMax=new Vector2(area.xMax/Screen.width,area.yMax/Screen.height);
            Vector2 keyboard=new Vector2((Input.GetKey(KeyCode.D)||Input.GetKey(KeyCode.RightArrow)?1:0)-(Input.GetKey(KeyCode.A)||Input.GetKey(KeyCode.LeftArrow)?1:0),(Input.GetKey(KeyCode.W)||Input.GetKey(KeyCode.UpArrow)?1:0)-(Input.GetKey(KeyCode.S)||Input.GetKey(KeyCode.DownArrow)?1:0));world.Move=world.Active?(keyboard.sqrMagnitude>0?keyboard:stick):Vector2.zero;
            if(Input.GetKeyDown(KeyCode.Space))world.Jump();if(Input.GetKeyDown(KeyCode.E))world.Interact();if(Input.GetKeyDown(KeyCode.H))world.Hint();if(Input.GetKeyDown(KeyCode.M)&&mapPanel)ToggleMap();
            if(Input.GetKeyDown(KeyCode.LeftShift))world.Sprint=true;if(Input.GetKeyUp(KeyCode.LeftShift))world.Sprint=false;
            if(Input.GetKeyDown(KeyCode.Escape)){if(world.Home)Application.Quit();else if(paused){world.SetPaused(false);ShowGame();}else{world.SetPaused(true);ShowPause();}}
            if(!world.Active&&!world.Home&&!world.Completed&&!paused)ShowPause();
            if(timeLabel)timeLabel.text=Format(world.Elapsed);if(interaction)interaction.text=world.NearbyBeacon>=0?"点亮":world.NearbyGate?"进入":"互动";
            if(toast&&Time.unscaledTime>toastUntil)toast.text="";
            frameTime=Mathf.Lerp(frameTime,Time.unscaledDeltaTime,.05f);fpsTimer+=Time.unscaledDeltaTime;if(fps&&fpsTimer>.5f){fpsTimer=0;fps.text=showFps?(1/Mathf.Max(frameTime,.001f)).ToString("0")+" FPS  ·  Unity":"";}
            mapTimer+=Time.unscaledDeltaTime;if(mapOpen&&mapTimer>.2f){mapTimer=0;DrawMap();}
        }
    }
}
