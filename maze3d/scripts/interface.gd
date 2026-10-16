extends Control
var game
var regular: Font = preload("res://assets/ui-regular.otf")
var bold: Font = preload("res://assets/ui-bold.otf")
var serif: Font = preload("res://assets/ui-title.otf")
var latin: Font = preload("res://assets/latin-font.otf")
var buttons: Array = []
const INK := Color("112c39")
const CREAM := Color("f5e8cf")
const GOLD := Color("eac489")
const MINT := Color("94d5c6")
const SOFT := Color("b0c4c6")
const PANEL := Color(.035,.10,.14,.87)
func factor() -> float:return size.y/720.0 if size.y>0 else 1.0
func width() -> float:return size.x/factor()
func logical(p: Vector2) -> Vector2:return p/factor()
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func hit(p: Vector2) -> String:
	for i in range(buttons.size()-1,-1,-1):
		if buttons[i].rect.has_point(p):return buttons[i].id
	return ""
func text(s: String,p: Vector2,sz: int=22,color: Color=CREAM,font: Font=null) -> void:
	draw_string(regular if font==null else font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func centered(s: String,p: Vector2,sz: int=22,color: Color=CREAM,font: Font=null) -> void:
	var f:Font=regular if font==null else font
	text(s,p-Vector2(f.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,sz).x/2,0),sz,color,f)
func panel(r: Rect2,color: Color=PANEL,radius: int=16,border: Color=Color(1,1,1,.10)) -> void:
	var style:=StyleBoxFlat.new();style.bg_color=color;style.set_corner_radius_all(radius);style.border_color=border;style.set_border_width_all(1);draw_style_box(style,r)
func button(id: String,label: String,r: Rect2,primary: bool=false,small: bool=false) -> void:
	panel(r,GOLD if primary else Color(.08,.18,.22,.94),12,Color(1,1,1,.20) if primary else Color(1,1,1,.14))
	centered(label,r.get_center()+Vector2(0,7),19 if small else 23,INK if primary else CREAM,bold)
	buttons.append({"id":id,"rect":r})
func diamond(p: Vector2,r: float,color: Color,filled: bool=true) -> void:
	var points:=PackedVector2Array([p+Vector2(0,-r),p+Vector2(r,0),p+Vector2(0,r),p+Vector2(-r,0)])
	if filled:draw_colored_polygon(points,color)
	else:points.append(points[0]);draw_polyline(points,color,1.5,true)
func line(a: Vector2,b: Vector2,c: Color=Color(1,1,1,.14),w: float=1) -> void:draw_line(a,b,c,w,true)
func _draw() -> void:
	if not game:return
	buttons.clear();draw_set_transform(Vector2.ZERO,0,Vector2.ONE*factor())
	var w:=width()
	if game.page=="home":draw_home(w);return
	draw_hud(w)
	match game.page:
		"pause":draw_pause(w)
		"map":draw_map(w)
		"win":draw_win(w)
		"confirm":draw_confirm(w)

func draw_home(w: float) -> void:
	# Editorial gradient: the live 3D courtyard remains the key visual.
	draw_polygon(PackedVector2Array([Vector2.ZERO,Vector2(w*.76,0),Vector2(w*.76,720),Vector2(0,720)]),PackedColorArray([Color(.027,.075,.105,.96),Color(.027,.075,.105,0),Color(.027,.075,.105,0),Color(.027,.075,.105,.96)]))
	draw_rect(Rect2(0,0,w,86),Color(.02,.06,.09,.16))
	diamond(Vector2(63,49),8,GOLD)
	text("PIPI MAZE",Vector2(83,57),24,CREAM,latin)
	text("3D EXPLORATION",Vector2(240,54),12,SOFT,latin)
	panel(Rect2(w-218,30,174,33),Color(.04,.12,.16,.6),16)
	centered("体验版  /  0.2.1",Vector2(w-131,52),14,SOFT)
	text("A LITTLE LIGHT. A WAY HOME.",Vector2(63,145),14,GOLD,latin)
	text("灯火",Vector2(58,241),80,CREAM,serif)
	text("遗迹",Vector2(58,330),80,CREAM,serif)
	line(Vector2(64,359),Vector2(107,359),GOLD,2)
	text("带一盏小灯，走进沉睡的迷宫。",Vector2(64,402),21,CREAM)
	text("点亮三座灯塔，找回回家的路。",Vector2(64,437),21,SOFT)
	var has_save:bool=not game.session.is_empty()
	button("continue" if has_save else "start","继续寻光  →" if has_save else "走进遗迹  →",Rect2(64,483,292,64),true)
	if has_save:
		button("start","重新开始所选章节",Rect2(64,559,292,43),false,true)
	else:text("左手移动  ·  右手环顾  ·  自由探索",Vector2(64,580),15,SOFT)
	text("CHOOSE YOUR JOURNEY",Vector2(w-586,526),12,GOLD,latin)
	for i in 3:
		var r:=Rect2(w-590+i*180,546,168,102)
		var selected:bool=game.chapter==i
		panel(r,Color(.10,.23,.27,.93) if selected else Color(.025,.09,.12,.75),12,GOLD if selected else Color(1,1,1,.13))
		text("0%d"%(i+1),r.position+Vector2(16,29),15,GOLD if selected else SOFT,latin)
		for star in 3:
			diamond(r.position+Vector2(116+star*13,24),3.5,GOLD,star<int(game.records.get(str(i),{}).get("stars",0)))
		text(game.world.maze.TITLES[i],r.position+Vector2(16,60),22,CREAM,bold)
		text(["入门 · 庭院","进阶 · 回廊","挑战 · 深境"][i],r.position+Vector2(16,85),13,SOFT)
		buttons.append({"id":"chapter%d"%i,"rect":r})
	line(Vector2(64,672),Vector2(w-48,672))
	text("3D 迷宫体验 Demo",Vector2(64,698),13,SOFT)
	text("离线游玩  /  自动保存  /  无时间限制",Vector2(w-340,698),13,SOFT)

func draw_hud(w: float) -> void:
	# Thin top fade keeps scenery legible while maintaining type contrast.
	for i in 20:draw_rect(Rect2(0,i*6,w,6),Color(.02,.07,.10,.55*(1-float(i)/20)))
	text("CHAPTER 0%d"%(game.chapter+1),Vector2(32,35),12,GOLD,latin)
	text(game.world.maze.TITLES[game.chapter],Vector2(31,69),28,CREAM,serif)
	text("点亮灯塔，唤醒出口",Vector2(32,96),14,SOFT)
	panel(Rect2(w/2-150,23,300,66),Color(.035,.11,.15,.79),14)
	for i in 3:
		var p:=Vector2(w/2-112+i*34,54)
		diamond(p,9,MINT if i in game.world.activated else Color(.5,.65,.66,.4),i in game.world.activated)
	text("灯塔  %d / 3"%game.world.activated.size(),Vector2(w/2+5,62),20,CREAM,bold)
	panel(Rect2(w-320,28,118,42),Color(.035,.11,.15,.8),20)
	diamond(Vector2(w-296,49),6,GOLD)
	text("%02d / 12"%game.world.collected.size(),Vector2(w-281,56),17,CREAM,latin)
	button("pause","Ⅱ",Rect2(w-77,26,48,44),false,true)
	text(time_text(game.world.elapsed),Vector2(w-185,56),17,SOFT,latin)
	panel(Rect2(w-179,91,150,172),Color(.025,.09,.12,.82),14)
	draw_minimap(Rect2(w-167,103,126,126),false)
	centered("探索地图  M",Vector2(w-104,248),12,SOFT)
	buttons.append({"id":"map","rect":Rect2(w-179,91,150,172)})
	if game.page=="play":
		draw_controls(w)
		if game.toast_timer>0:
			var tw:float=regular.get_string_size(game.toast,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+56
			panel(Rect2(w/2-tw/2,116,tw,45),Color(.04,.14,.18,.91),22)
			centered(game.toast,Vector2(w/2,145),18,CREAM)
		if game.tutorial_time>0:
			panel(Rect2(w/2-240,625,480,56),Color(.035,.10,.14,.85),13)
			centered("左侧滑动移动  ·  右侧拖动环顾",Vector2(w/2,648),17,CREAM)
			centered("WASD 移动 / Shift 冲刺 / E 互动 / H 引路",Vector2(w/2,670),12,SOFT)
		elif game.world.near_beacon<0 and not game.world.near_gate:
			centered("右侧拖动环顾  ·  靠近灯塔后点亮",Vector2(w/2,683),13,Color(.85,.92,.91,.68))
		# A nearby world label gives interaction a clear physical anchor.
		for i in game.world.light_nodes.size():
			if i in game.world.activated:continue
			var p:Vector3=game.world.light_nodes[i].global_position+Vector3(0,.7,0)
			if p.distance_to(game.world.player.position)<9 and not game.world.camera.is_position_behind(p):
				var screen:Vector2=game.world.camera.unproject_position(p)/factor()
				if screen.x>100 and screen.x<w-190 and screen.y>180 and screen.y<440:
					panel(Rect2(screen-Vector2(44,27),Vector2(88,28)),Color(.04,.13,.16,.75),14)
					centered("未点亮",screen-Vector2(0,7),13,CREAM)

func draw_controls(w: float) -> void:
	var origin:Vector2=game.joystick_origin if game.move_pointer!=-99 else Vector2(155,565)
	draw_circle(origin,72,Color(.02,.09,.12,.23),true,-1,true)
	draw_arc(origin,65,0,TAU,64,Color(.85,.94,.90,.28),1.5,true)
	draw_arc(origin,49,0,TAU,48,Color(.85,.94,.90,.10),1,true)
	for a in [0,PI/2,PI,PI*1.5]:
		var v:=Vector2(cos(a),sin(a));line(origin+v*57,origin+v*62,Color(.9,.95,.9,.4),2)
	var knob:Vector2=origin+game.joystick*45
	draw_circle(knob,27,Color(.77,.89,.84,.20),true,-1,true)
	draw_arc(knob,27,0,TAU,48,Color(.92,.96,.87,.65),1.5,true)
	centered("移动",Vector2(155,665),14,Color(.85,.92,.91,.7))
	var run:=Vector2(w-105,564)
	draw_circle(run,48,Color(.05,.15,.19,.68),true,-1,true)
	draw_arc(run,48,0,TAU,64,Color(.9,.93,.84,.23),2,true)
	draw_arc(run,48,-PI/2,-PI/2+TAU*maxf(.001,game.world.energy),64,GOLD,3,true)
	line(run+Vector2(-9,3),run+Vector2(1,-11),CREAM,3);line(run+Vector2(1,-11),run+Vector2(11,3),CREAM,3)
	line(run+Vector2(-9,14),run+Vector2(1,0),CREAM,2);line(run+Vector2(1,0),run+Vector2(11,14),CREAM,2)
	centered("按住冲刺",run+Vector2(0,73),14,CREAM)
	buttons.append({"id":"sprint","rect":Rect2(run-Vector2(54,54),Vector2(108,108))})
	var hint:=Vector2(w-228,612)
	draw_circle(hint,34,Color(.04,.13,.17,.80),true,-1,true);draw_arc(hint,34,0,TAU,48,Color(.83,.91,.84,.3),1.3,true)
	if game.world.hint_cooldown>0:centered(str(ceili(game.world.hint_cooldown)),hint+Vector2(0,8),22,SOFT,latin)
	else:diamond(hint,11,GOLD,false);diamond(hint,4,GOLD)
	centered("引路灯",hint+Vector2(0,59),14,CREAM)
	buttons.append({"id":"hint","rect":Rect2(hint-Vector2(39,39),Vector2(78,78))})
	button("camera","回正",Rect2(w-129,384,76,34),false,true)
	if game.world.near_beacon>=0 or game.world.near_gate:
		var label:="点亮灯塔  E" if game.world.near_beacon>=0 else ("走进出口  E" if game.world.activated.size()==3 else "查看出口  E")
		button("interact",label,Rect2(w-280,442,226,56),true)

func draw_pause(w: float) -> void:
	buttons.clear();draw_rect(Rect2(0,0,w,720),Color(.015,.05,.075,.78))
	var x:=w/2-255
	panel(Rect2(x,68,510,584),Color(.055,.14,.18,.98),24)
	centered("TAKE A BREATH",Vector2(w/2,112),13,GOLD,latin)
	centered("灯火为你停留",Vector2(w/2,165),36,CREAM,serif)
	centered("探索进度已自动保存",Vector2(w/2,201),17,SOFT)
	button("resume","继续探索",Rect2(x+48,236,414,57),true)
	button("sound","声音与震动  ·  "+("开" if game.settings.sound else "关"),Rect2(x+48,311,201,48),false,true)
	button("quality","画质  ·  "+("精致" if game.settings.quality else "流畅"),Rect2(x+261,311,201,48),false,true)
	button("sensitivity","镜头灵敏度  ·  "+("标准" if game.settings.sensitivity==1.0 else ("灵敏" if game.settings.sensitivity>1 else "柔和")),Rect2(x+48,371,414,45),false,true)
	button("retry","重新探索本章",Rect2(x+48,430,414,48),false,true)
	button("home","返回首页",Rect2(x+48,491,414,48),false,true)
	centered("WASD 移动  /  拖动或 Q、R 转向  /  C 回正",Vector2(w/2,581),14,SOFT)
	centered("E 点亮  /  H 引路  /  M 地图  /  Esc 暂停",Vector2(w/2,607),14,SOFT)
func draw_map(w: float) -> void:
	buttons.clear();draw_rect(Rect2(0,0,w,720),Color(.015,.05,.075,.92))
	text("走过的路，都会留下光",Vector2(64,80),32,CREAM,serif)
	text("未探索区域会随着脚步逐渐显现",Vector2(66,115),17,SOFT)
	var r:=Rect2(w/2-238,150,476,476)
	panel(Rect2(r.position-Vector2(16,16),r.size+Vector2(32,32)),Color(.08,.18,.22,1),20)
	draw_minimap(r,true)
	button("close_map","返回探索  ×",Rect2(w-226,40,170,48),false,true)
	diamond(Vector2(90,229),7,GOLD);text("灯塔",Vector2(113,236),19,CREAM)
	draw_circle(Vector2(90,279),6,MINT);text("你的位置",Vector2(113,286),19,CREAM)
	diamond(Vector2(90,329),8,MINT,false);text("归途之门",Vector2(113,336),19,CREAM)
	text("引路灯可以帮你找到",Vector2(70,420),16,SOFT)
	text("最近一座未点亮的灯塔。",Vector2(70,449),16,SOFT)
	centered("地图查看时，探索计时暂停",Vector2(w/2,679),14,SOFT)
func draw_minimap(r: Rect2,full: bool) -> void:
	var maze=game.world.maze
	var tile:float=r.size.x/maze.width
	for z in maze.width:
		for x in maze.width:
			var c:=Vector2i(x,z)
			var p:Vector2=r.position+Vector2(x,z)*tile
			if maze.seen.has(c):draw_rect(Rect2(p,Vector2.ONE*(tile-.7)),Color("668687") if maze.walkable(c) else Color("233f49"))
	for i in 3:
		var c:Vector2i=maze.beacons[i]
		if maze.seen.has(c):diamond(r.position+(Vector2(c)+Vector2(.5,.5))*tile,maxf(3,tile*.24),MINT if i in game.world.activated else GOLD)
	if maze.seen.has(maze.goal):diamond(r.position+(Vector2(maze.goal)+Vector2(.5,.5))*tile,maxf(3,tile*.30),MINT,false)
	var pp:Vector3=game.world.player.position
	var pc:Vector2=Vector2(pp.x,pp.z)/maze.TILE+Vector2.ONE*(maze.width/2)+Vector2(.5,.5)
	var point:Vector2=r.position+pc*tile
	draw_circle(point,6 if full else 3.5,CREAM,true,-1,true)
	var forward:=Vector2(sin(game.world.yaw),-cos(game.world.yaw))
	line(point+forward*3,point+forward*(15 if full else 9),GOLD,2)
func draw_win(w: float) -> void:
	buttons.clear();draw_rect(Rect2(0,0,w,720),Color(.015,.065,.085,.76))
	var x:=w/2-270
	panel(Rect2(x,58,540,604),Color(.05,.15,.19,.97),24,GOLD.darkened(.55))
	centered("JOURNEY COMPLETE",Vector2(w/2,108),14,GOLD,latin)
	for i in 3:diamond(Vector2(w/2-50+i*50,158),14,GOLD if i<game.finish_stars else Color(.4,.5,.5,.5),i<game.finish_stars)
	centered("你让遗迹重新发光",Vector2(w/2,226),37,CREAM,serif)
	centered(game.world.maze.TITLES[game.chapter]+"  ·  探索完成",Vector2(w/2,265),19,SOFT)
	line(Vector2(x+50,298),Vector2(x+490,298))
	for i in 3:
		var cx:=x+104+i*166
		centered([time_text(game.world.elapsed),"%d / 12"%game.world.collected.size(),str(game.world.hints_used)][i],Vector2(cx,349),27,CREAM,latin)
		centered(["探索用时","收集萤光","引路次数"][i],Vector2(cx,380),15,SOFT)
	centered("6 枚萤光获得双星，12 枚点亮三星",Vector2(w/2,425),15,GOLD)
	button("next","进入下一章  →" if game.chapter<2 else "再访初光庭院  →",Rect2(x+54,463,432,59),true)
	button("home","返回首页",Rect2(x+54,539,432,48),false,true)
	centered("灯火与最佳记录已保存在本机",Vector2(w/2,627),13,SOFT)
func draw_confirm(w: float) -> void:
	buttons.clear();draw_rect(Rect2(0,0,w,720),Color(.01,.05,.07,.83))
	panel(Rect2(w/2-245,225,490,270),PANEL,22)
	centered("重新探索这一章？",Vector2(w/2,285),29,CREAM,serif)
	centered("本章当前进度会重置，最佳记录保留。",Vector2(w/2,335),18,SOFT)
	button("cancel_retry","保留进度",Rect2(w/2-195,384,185,58),false)
	button("confirm_retry","重新开始",Rect2(w/2+10,384,185,58),true)
func time_text(seconds: float) -> String:return "%02d:%02d"%[int(seconds)/60,int(seconds)%60]
