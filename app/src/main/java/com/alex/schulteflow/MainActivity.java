package com.alex.schulteflow;

import android.app.Activity;
import android.app.Dialog;
import android.content.SharedPreferences;
import android.content.res.ColorStateList;
import android.graphics.*;
import android.graphics.drawable.*;
import android.media.*;
import android.os.*;
import android.view.*;
import android.view.animation.OvershootInterpolator;
import android.widget.*;
import org.json.*;
import java.util.*;

/** Offline native Android UI. No WebView, advertising, analytics or network permission. */
public final class MainActivity extends Activity {
 private static final int BG=0xff0c191d,PANEL=0xff15292e,TILE=0xff1a3036,LINE=0xff2b4246;
 private static final int WHITE=0xfff1f6ef,MUTED=0xff95aaa9,LIME=0xffc8f77a,MINT=0xff78d9cb,RED=0xffff9992;
 private final Handler handler=new Handler(Looper.getMainLooper());
 private final Random random=new Random();
 private SharedPreferences prefs; private GameSession game;
 private FrameLayout root,veil; private SquareGrid grid; private Sparks sparks;
 private LinearLayout modes,actions; private TextView target,timer,status,best,progressText,veilTitle,veilHint;
 private TextView[] cells;private ProgressBar progress;private Dialog dialog;
 private boolean active,counting,soundOn,hapticsOn;private int token,combo;private long lastHit,oldBest;
 private SoundPool audio;private final int[] notes=new int[6];private int miss,finish;
 private final Set<Integer> loaded=new HashSet<Integer>();
 private final Runnable tick=new Runnable(){public void run(){if(!active)return;if(game.state()==GameSession.State.RUNNING)timer.setText(time(game.elapsed(now())));handler.postDelayed(this,33);}};
 private long now(){return SystemClock.elapsedRealtime();}
 private int dp(float n){return Math.round(n*getResources().getDisplayMetrics().density);}
 public static String time(long ms){return String.format(Locale.US,"%02d:%02d.%02d",ms/60000,ms/1000%60,ms/10%100);}
 @Override public void onCreate(Bundle b){
  super.onCreate(b);prefs=getSharedPreferences("schulte_flow",MODE_PRIVATE);
  soundOn=prefs.getBoolean("sound",true);hapticsOn=prefs.getBoolean("haptics",true);
  int size=prefs.getInt("size",5);if(size<3||size>5)size=5;
  game=new GameSession(size,random);restore();initAudio();
  getWindow().setStatusBarColor(BG);getWindow().setNavigationBarColor(BG);
  getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_STABLE|View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN|View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
  buildUi();refresh();
 }
 private TextView label(String s,float size,int color,boolean bold){TextView t=new TextView(this);t.setText(s);t.setTextSize(size);t.setTextColor(color);t.setIncludeFontPadding(false);t.setGravity(Gravity.CENTER_VERTICAL);t.setTypeface(Typeface.create(bold?"sans-serif-medium":"sans-serif",0));return t;}
 private GradientDrawable shape(int color,int radius,int border){GradientDrawable d=new GradientDrawable();d.setColor(color);d.setCornerRadius(dp(radius));if(border!=0)d.setStroke(dp(1),border);return d;}
 private RippleDrawable ripple(int color,int radius,int border){return new RippleDrawable(ColorStateList.valueOf(0x3978d9cb),shape(color,radius,border),shape(Color.WHITE,radius,0));}
 private TextView button(String s,boolean primary,String tag,View.OnClickListener click){
  TextView b=label(s,16,primary?BG:WHITE,true);b.setGravity(Gravity.CENTER);b.setTag(tag);b.setPadding(dp(10),dp(4),dp(10),dp(4));b.setBackground(ripple(primary?LIME:PANEL,17,primary?0:LINE));b.setFocusable(true);b.setOnClickListener(click);
  b.setAccessibilityDelegate(new View.AccessibilityDelegate(){@Override public void onInitializeAccessibilityNodeInfo(View v,android.view.accessibility.AccessibilityNodeInfo i){super.onInitializeAccessibilityNodeInfo(v,i);i.setClassName("android.widget.Button");}});return b;
 }
 private LinearLayout col(){LinearLayout l=new LinearLayout(this);l.setOrientation(1);return l;}
 private LinearLayout row(){LinearLayout l=new LinearLayout(this);l.setGravity(Gravity.CENTER_VERTICAL);return l;}
 private void add(LinearLayout l,View v,int h){l.addView(v,new LinearLayout.LayoutParams(-1,h<0?h:dp(h)));}
 private void gap(LinearLayout l,int h){l.addView(new View(this),new LinearLayout.LayoutParams(1,dp(h)));}
 private void weight(LinearLayout l,View v,int h){l.addView(v,new LinearLayout.LayoutParams(0,h<0?h:dp(h),1));}
 private void buildUi(){
  root=new FrameLayout(this);root.setBackground(new GradientDrawable(GradientDrawable.Orientation.TL_BR,new int[]{0xff10262b,BG,BG}));
  root.setOnApplyWindowInsetsListener((v,i)->{v.setPadding(i.getSystemWindowInsetLeft(),i.getSystemWindowInsetTop(),i.getSystemWindowInsetRight(),i.getSystemWindowInsetBottom());return i.consumeSystemWindowInsets();});
  LinearLayout shell=col();root.addView(shell,new FrameLayout.LayoutParams(Math.min(getResources().getDisplayMetrics().widthPixels,dp(500)),-1,Gravity.CENTER_HORIZONTAL));
  ScrollView scroll=new ScrollView(this);scroll.setVerticalScrollBarEnabled(false);scroll.setOverScrollMode(View.OVER_SCROLL_NEVER);shell.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
  LinearLayout body=col();body.setPadding(dp(20),dp(12),dp(20),dp(8));scroll.addView(body);
  LinearLayout header=row();TextView logo=label("▦",27,LIME,true);logo.setGravity(Gravity.CENTER);logo.setBackground(shape(PANEL,12,LINE));header.addView(logo,new LinearLayout.LayoutParams(dp(40),dp(40)));
  LinearLayout branding=col();branding.setPadding(dp(10),0,0,0);add(branding,label("循光",21,WHITE,true),27);TextView sub=label("SCHULTE FLOW",9,MUTED,false);sub.setLetterSpacing(.09f);add(branding,sub,15);weight(header,branding,44);
  TextView settings=button("···",false,"settings",v->settings());settings.setTextSize(24);settings.setContentDescription("音效、触感与玩法设置");header.addView(settings,new LinearLayout.LayoutParams(dp(48),dp(44)));add(body,header,44);gap(body,15);
  modes=row();modes.setBackground(shape(0xff091519,14,LINE));modes.setPadding(dp(4),dp(4),dp(4),dp(4));
  for(int n=3;n<=5;n++){final int size=n;TextView mode=button(n+" × "+n,false,"mode"+n,v->choose(size));mode.setTextSize(14);mode.setSingleLine(true);weight(modes,mode,38);}add(body,modes,46);gap(body,15);
  LinearLayout metrics=row();LinearLayout next=col();add(next,label("下一个目标",11,MUTED,false),19);target=label("01",43,LIME,true);target.setTag("target");add(next,target,49);weight(metrics,next,68);
  LinearLayout clock=col();timer=label("00:00.00",25,WHITE,false);timer.setTag("timer");timer.setGravity(Gravity.RIGHT|Gravity.CENTER_VERTICAL);add(clock,timer,38);best=label("",11,MUTED,false);best.setGravity(Gravity.RIGHT|Gravity.CENTER_VERTICAL);add(clock,best,24);metrics.addView(clock,new LinearLayout.LayoutParams(0,dp(68),1.65f));add(body,metrics,68);gap(body,9);
  LinearLayout info=row();status=label("准备好，就开始",12,MINT,false);status.setTag("status");weight(info,status,26);progressText=label("",11,MUTED,false);progressText.setTag("progress_label");info.addView(progressText);add(body,info,26);
  progress=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);progress.setProgressTintList(ColorStateList.valueOf(LIME));progress.setProgressBackgroundTintList(ColorStateList.valueOf(LINE));add(body,progress,4);gap(body,11);
  FrameLayout board=new FrameLayout(this);grid=new SquareGrid();board.addView(grid,new FrameLayout.LayoutParams(-1,-2));sparks=new Sparks();sparks.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);board.addView(sparks,new FrameLayout.LayoutParams(-1,-1));
  veil=new FrameLayout(this);veil.setBackground(shape(0xf70c191d,18,LINE));veil.setClickable(true);veil.setFocusable(true);LinearLayout cover=col();cover.setGravity(Gravity.CENTER);veilTitle=label("",28,LIME,true);veilTitle.setGravity(Gravity.CENTER);add(cover,veilTitle,70);veilHint=label("",13,MUTED,false);veilHint.setGravity(Gravity.CENTER);add(cover,veilHint,42);veil.addView(cover,new FrameLayout.LayoutParams(-1,-2,Gravity.CENTER));board.addView(veil,new FrameLayout.LayoutParams(-1,-1));add(body,board,-2);gap(body,9);
  TextView tip=label("从 1 开始依次寻找 · 点错不加时",11,MUTED,false);tip.setGravity(Gravity.CENTER);add(body,tip,22);
  LinearLayout footer=col();footer.setBackgroundColor(BG);footer.setPadding(dp(20),dp(9),dp(20),dp(8));actions=row();add(footer,actions,54);TextView note=label("跟随自己的节奏",10,MUTED,false);note.setGravity(Gravity.CENTER);add(footer,note,23);add(shell,footer,94);
  setContentView(root);root.requestApplyInsets();populate();
 }
 private final class SquareGrid extends GridLayout{
  SquareGrid(){super(MainActivity.this);setUseDefaultMargins(false);}
  @Override protected void onMeasure(int w,int h){super.onMeasure(w,View.MeasureSpec.makeMeasureSpec(View.MeasureSpec.getSize(w),View.MeasureSpec.EXACTLY));}
 }
 private void populate(){
  grid.removeAllViews();grid.setColumnCount(game.size());grid.setRowCount(game.size());cells=new TextView[game.count()+1];int[] values=game.board();
  for(int i=0;i<values.length;i++){final int n=values[i];TextView t=label(String.valueOf(n),game.size()==3?36:game.size()==4?29:23,WHITE,true);t.setGravity(Gravity.CENTER);t.setTag("tile_"+n);t.setFocusable(true);t.setOnClickListener(v->tap(n));GridLayout.LayoutParams p=new GridLayout.LayoutParams(GridLayout.spec(i/game.size(),1f),GridLayout.spec(i%game.size(),1f));p.width=0;p.height=0;p.setMargins(dp(3),dp(3),dp(3),dp(3));grid.addView(t,p);cells[n]=t;}
 }
 private void refresh(){
  timer.setText(time(game.elapsed(now())));target.setText(game.state()==GameSession.State.FINISHED?"✓":String.format(Locale.US,"%02d",game.next()));
  long record=prefs.getLong("best_"+game.size(),0);best.setText("最佳  "+(record==0?"等待你点亮":time(record)));progress.setMax(game.count());progress.setProgress(game.completed());progressText.setText(game.completed()+" / "+game.count());
  for(int n=1;n<=game.count();n++){boolean done=n<game.next();TextView t=cells[n];t.setBackground(ripple(done?0xff193d37:TILE,13,done?0xff326255:LINE));t.setTextColor(done?MINT:WHITE);t.setAlpha(done?.7f:1);t.setClickable(game.state()==GameSession.State.RUNNING&&!done);t.setContentDescription("数字 "+n+(done?"，已找到":""));}
  for(int i=0;i<3;i++){TextView v=(TextView)modes.getChildAt(i);boolean selected=i+3==game.size();v.setBackground(ripple(selected?0xff2a4140:0,10,0));v.setTextColor(selected?LIME:MUTED);v.setSelected(selected);}
  boolean paused=game.state()==GameSession.State.PAUSED;veil.setVisibility(paused||counting?View.VISIBLE:View.GONE);grid.setAlpha(game.state()==GameSession.State.READY?.44f:1);grid.setImportantForAccessibility(paused||counting?View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS:View.IMPORTANT_FOR_ACCESSIBILITY_AUTO);
  if(paused){veilTitle.setTextSize(28);veilTitle.setText("稍作停留");veilHint.setText("计时已暂停 · 你的进度还在");status.setText("休息一下，再接着来");}
  actions.removeAllViews();
  if(game.state()==GameSession.State.RUNNING||paused){weight(actions,button(paused?"继续专注  →":"Ⅱ  暂停一下",paused,paused?"resume":"pause",v->{haptic(false);if(game.state()==GameSession.State.RUNNING)pause();else{game.resume(now());combo=0;lastHit=0;status.setText("继续寻找 "+game.next());refresh();wake();}}),54);View spacer=new View(this);actions.addView(spacer,new LinearLayout.LayoutParams(dp(10),1));TextView restart=button("↻",false,"restart",v->confirm(game.size()));restart.setTextSize(27);restart.setContentDescription("重新开始");actions.addView(restart,new LinearLayout.LayoutParams(dp(56),dp(54)));}
  else{TextView start=button(counting?"准备进入专注":game.state()==GameSession.State.FINISHED?"再来一局  →":"开始专注  →",true,"start",v->begin());start.setEnabled(!counting);start.setAlpha(counting?.7f:1);weight(actions,start,54);}
 }
 private void choose(int size){if(counting||size==game.size())return;haptic(false);if(game.state()==GameSession.State.RUNNING||game.state()==GameSession.State.PAUSED)confirm(size);else fresh(size);}
 private void fresh(int size){counting=false;token++;game=new GameSession(size,random);combo=0;lastHit=0;prefs.edit().putInt("size",size).remove("round").apply();populate();status.setText("准备好，就开始");status.setTextColor(MINT);refresh();wake();}
 private void begin(){if(counting)return;fresh(game.size());counting=true;int id=++token;refresh();status.setText("把目光放在表格中央");veilTitle.setTextSize(66);veilHint.setText("从 1 开始，按顺序点亮每一格");count(3,id);wake();}
 private void count(int n,int id){if(id!=token||!counting)return;if(n==0){counting=false;game.start(now());status.setText("找到 1，让专注发生");refresh();wake();return;}veilTitle.setText(String.valueOf(n));veilTitle.setScaleX(.8f);veilTitle.setScaleY(.8f);veilTitle.animate().scaleX(1).scaleY(1).setDuration(260).setInterpolator(new OvershootInterpolator()).start();play(notes[0],.35f);haptic(false);handler.postDelayed(()->count(n-1,id),650);}
 private void pause(){game.pause(now());save();refresh();wake();}
 private void tap(int n){
  GameSession.Hit result=game.tap(n,now());if(result==GameSession.Hit.IGNORED)return;final TextView cell=cells[n];
  if(result==GameSession.Hit.WRONG){combo=0;lastHit=0;haptic(true);play(miss,.5f);status.setTextColor(RED);status.setText("先找 "+game.next()+"  ·  误触 "+game.mistakes());cell.setBackground(ripple(0xff542c31,13,RED));cell.animate().cancel();cell.animate().translationX(dp(5)).setDuration(45).withEndAction(()->cell.animate().translationX(-dp(5)).setDuration(60).withEndAction(()->cell.animate().translationX(0).setDuration(60).withEndAction(()->{if(n<cells.length&&cell==cells[n]&&game.next()<=n)cell.setBackground(ripple(TILE,13,LINE));}).start()).start()).start();save();return;}
  long t=now();combo=lastHit>0&&t-lastHit<1600?combo+1:1;lastHit=t;haptic(false);play(notes[Math.min(combo-1,5)],.6f);
  cell.animate().cancel();cell.setTranslationX(0);cell.setScaleX(.86f);cell.setScaleY(.86f);cell.animate().scaleX(1).scaleY(1).setDuration(230).setInterpolator(new OvershootInterpolator(2.4f)).start();sparks.burst(cell.getX()+cell.getWidth()/2f,cell.getY()+cell.getHeight()/2f,false);
  status.setTextColor(MINT);status.setText(combo>=3?"连击 ×"+combo+"  节奏正好！":"✓ 找到了 "+n+"  继续寻找 "+game.next());target.setScaleX(1.12f);target.setScaleY(1.12f);target.animate().scaleX(1).scaleY(1).setDuration(170).start();refresh();
  if(result==GameSession.Hit.COMPLETE){long elapsed=Math.max(1,game.elapsed(now()));oldBest=prefs.getLong("best_"+game.size(),0);SharedPreferences.Editor edit=prefs.edit().remove("round").putInt("rounds",prefs.getInt("rounds",0)+1);if(oldBest==0||elapsed<oldBest)edit.putLong("best_"+game.size(),elapsed);edit.apply();status.setText("全部点亮，做得漂亮！");status.setTextColor(LIME);play(finish,.7f);sparks.burst(grid.getWidth()/2f,grid.getHeight()/2f,true);wake();handler.postDelayed(()->{if(active&&game.state()==GameSession.State.FINISHED)result();},420);}else save();
 }
 private Dialog newDialog(){if(dialog!=null&&dialog.isShowing())dialog.dismiss();dialog=new Dialog(this);dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);dialog.getWindow().setBackgroundDrawable(shape(PANEL,25,LINE));dialog.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND);WindowManager.LayoutParams p=dialog.getWindow().getAttributes();p.dimAmount=.72f;dialog.getWindow().setAttributes(p);return dialog;}
 private LinearLayout dialogBody(Dialog d){LinearLayout b=col();b.setPadding(dp(23),dp(23),dp(23),dp(22));ScrollView s=new ScrollView(this);s.addView(b);d.setContentView(s);return b;}
 private void show(Dialog d){d.show();d.getWindow().setLayout(Math.min(getResources().getDisplayMetrics().widthPixels-dp(36),dp(430)),-2);}
 private void centered(LinearLayout b,String text,int size,int color,int height){TextView t=label(text,size,color,true);t.setGravity(Gravity.CENTER);add(b,t,height);}
 private void result(){
  Dialog d=newDialog();LinearLayout b=dialogBody(d);long elapsed=Math.max(1,game.elapsed(now()));boolean record=oldBest>0&&elapsed<oldBest;
  centered(b,record?"↗ 刷新个人最佳":"✦ 每一格，都被你点亮",13,LIME,30);centered(b,"专注完成",28,WHITE,48);
  TextView score=label(time(elapsed),40,LIME,false);score.setGravity(Gravity.CENTER);score.setTag("result_time");add(b,score,62);centered(b,game.size()+" × "+game.size()+" / "+game.count()+" 个数字",13,MUTED,28);gap(b,17);
  LinearLayout stats=row();metric(stats,"准确率",String.format(Locale.US,"%.0f%%",game.count()*100.0/(game.count()+game.mistakes())));metric(stats,"误触",String.valueOf(game.mistakes()));metric(stats,"秒 / 格",String.format(Locale.US,"%.2f",elapsed/1000.0/game.count()));add(b,stats,67);gap(b,16);
  String note=oldBest==0?"第一份纪录已保存。下次，和自己比。":record?"比上次最佳快了 "+String.format(Locale.US,"%.2f",(oldBest-elapsed)/1000.0)+" 秒！":"本档最佳 "+time(Math.min(oldBest,elapsed));centered(b,note,12,MUTED,42);gap(b,8);
  add(b,button("再来一局  →",true,"again",v->{d.dismiss();begin();}),52);gap(b,10);add(b,button("回到练习",false,"result_close",v->{d.dismiss();fresh(game.size());}),48);show(d);
 }
 private void metric(LinearLayout r,String title,String value){LinearLayout c=col();centered(c,value,22,WHITE,34);centered(c,title,11,MUTED,25);weight(r,c,64);}
 private void settings(){
  if(counting)return;if(game.state()==GameSession.State.RUNNING)pause();Dialog d=newDialog();LinearLayout b=dialogBody(d);add(b,label("属于你的节奏",24,WHITE,true),43);gap(b,12);
  Switch sound=new Switch(this);sound.setText("轻柔音效");sound.setTextColor(WHITE);sound.setTag("sound_toggle");sound.setChecked(soundOn);add(b,sound,54);sound.setOnCheckedChangeListener((v,on)->{soundOn=on;prefs.edit().putBoolean("sound",on).apply();if(on)play(notes[2],.5f);});
  Switch vibration=new Switch(this);vibration.setText("点按触感");vibration.setTextColor(WHITE);vibration.setTag("haptic_toggle");vibration.setChecked(hapticsOn);add(b,vibration,54);vibration.setOnCheckedChangeListener((v,on)->{hapticsOn=on;prefs.edit().putBoolean("haptics",on).apply();if(on)haptic(false);});gap(b,16);
  TextView help=label("怎么玩\n\n从 1 开始，依次点击所有数字。\n目光尽量放在中央，尝试用余光寻找。\n点错会提示，但不会额外增加时间。\n暂停或切到后台时，计时会停止。\n\n已完成 "+prefs.getInt("rounds",0)+" 次练习\n离线运行 · 成绩仅保存在本机\n触感会遵循手机的系统设置。",13,MUTED,false);help.setLineSpacing(dp(4),1);add(b,help,-2);gap(b,22);add(b,button("准备好了",true,"settings_close",v->d.dismiss()),50);show(d);
 }
 private void confirm(int size){if(game.state()==GameSession.State.RUNNING)pause();Dialog d=newDialog();LinearLayout b=dialogBody(d);add(b,label("换一轮新的数字？",23,WHITE,true),43);add(b,label("当前这一局会结束，已保存的最佳纪录会保留。",14,MUTED,false),66);gap(b,10);add(b,button("开始新一局",true,"confirm_restart",v->{d.dismiss();fresh(size);begin();}),52);gap(b,10);add(b,button("保留这一局",false,"cancel_restart",v->d.dismiss()),48);show(d);}
 private void initAudio(){audio=new SoundPool.Builder().setMaxStreams(5).setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()).build();audio.setOnLoadCompleteListener((pool,id,code)->{if(code==0)loaded.add(id);});for(int i=0;i<6;i++)notes[i]=audio.load(this,getResources().getIdentifier("hit"+i,"raw",getPackageName()),1);miss=audio.load(this,R.raw.miss,1);finish=audio.load(this,R.raw.complete,1);setVolumeControlStream(AudioManager.STREAM_MUSIC);}
 private void play(int id,float volume){if(active&&soundOn&&audio!=null&&loaded.contains(id))audio.play(id,volume,volume,1,0,1);}
 private void haptic(boolean error){if(hapticsOn&&root!=null)root.performHapticFeedback(error?(Build.VERSION.SDK_INT>=30?HapticFeedbackConstants.REJECT:HapticFeedbackConstants.LONG_PRESS):HapticFeedbackConstants.KEYBOARD_TAP);}
 private void save(){if(game.state()!=GameSession.State.RUNNING&&game.state()!=GameSession.State.PAUSED)return;try{JSONObject j=new JSONObject();j.put("size",game.size());j.put("next",game.next());j.put("mistakes",game.mistakes());j.put("elapsed",game.elapsed(now()));JSONArray a=new JSONArray();for(int n:game.board())a.put(n);j.put("board",a);prefs.edit().putString("round",j.toString()).apply();}catch(JSONException ignored){}}
 private void restore(){try{String s=prefs.getString("round",null);if(s==null)return;JSONObject j=new JSONObject(s);JSONArray a=j.getJSONArray("board");int[] board=new int[a.length()];for(int i=0;i<board.length;i++)board[i]=a.getInt(i);game=GameSession.restore(j.getInt("size"),board,j.getInt("next"),j.getInt("mistakes"),j.getLong("elapsed"));}catch(Exception ignored){prefs.edit().remove("round").apply();}}
 private void wake(){if(active&&(counting||game.state()==GameSession.State.RUNNING))getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);else getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);}
 @Override protected void onResume(){super.onResume();active=true;handler.removeCallbacks(tick);handler.post(tick);wake();}
 @Override protected void onPause(){super.onPause();active=false;handler.removeCallbacks(tick);if(counting){counting=false;token++;status.setText("准备好，就开始");}game.pause(now());save();refresh();wake();}
 @Override protected void onDestroy(){handler.removeCallbacksAndMessages(null);if(audio!=null){audio.release();audio=null;}if(dialog!=null)dialog.dismiss();super.onDestroy();}
 @Override public void onBackPressed(){if(counting){counting=false;token++;status.setText("准备好，就开始");refresh();wake();return;}if(game.state()==GameSession.State.RUNNING){pause();return;}super.onBackPressed();}
 private final class Sparks extends View {
  private final Paint paint=new Paint(3);private final ArrayList<Dot> dots=new ArrayList<Dot>();
  Sparks(){super(MainActivity.this);}
  void burst(float x,float y,boolean celebration){long start=now();for(int i=0;i<(celebration?60:13);i++){float a=random.nextFloat()*6.28318f,v=dp(celebration?90+random.nextInt(150):35+random.nextInt(55));dots.add(new Dot(x,y,(float)Math.cos(a)*v,(float)Math.sin(a)*v,dp(celebration?3:2),start,celebration?1200:480,i%3==0?WHITE:i%2==0?LIME:MINT));}invalidate();}
  @Override protected void onDraw(Canvas c){super.onDraw(c);long current=now();for(int i=dots.size()-1;i>=0;i--){Dot p=dots.get(i);float age=current-p.start,t=age/p.life;if(t>=1){dots.remove(i);continue;}float seconds=age/1000;paint.setColor(p.color);paint.setAlpha(Math.round(230*(1-t)));c.drawCircle(p.x+p.vx*seconds,p.y+p.vy*seconds+dp(45)*seconds*seconds,p.r*(1-t*.5f),paint);}if(!dots.isEmpty())postInvalidateOnAnimation();}
 }
 private static final class Dot{final float x,y,vx,vy,r,life;final long start;final int color;Dot(float x,float y,float vx,float vy,float r,long start,float life,int color){this.x=x;this.y=y;this.vx=vx;this.vy=vy;this.r=r;this.start=start;this.life=life;this.color=color;}}
}
