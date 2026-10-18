"""Brown fan model, based on the official Oshiri Tantei character illustration.
Run with Blender 4.3+: blender -b -t 4 --python scripts/maze3d/brown_model.py
Coordinates: Z up, -Y forward. Named pivots remain editable and animate in Godot.
"""
import bpy, math, json, os
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'maze3d/assets/models'
SOURCE=ROOT/'model-source/maze3d'
PREVIEW=ROOT/'docs/maze3d/brown'
for p in [OUT,SOURCE,PREVIEW]:p.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
M={};parts=[]
def linear(v):return v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4
def material(name,color,rough=.78):
    rgb=[linear(int(color[i:i+2],16)/255) for i in (0,2,4)]
    m=bpy.data.materials.new(name);m.diffuse_color=(*rgb,1);m.use_nodes=True
    s=m.node_tree.nodes.get('Principled BSDF');s.inputs['Base Color'].default_value=(*rgb,1);s.inputs['Roughness'].default_value=rough
    M[name]=m;return m
for n,c,r in [('Fur','BD702B',.85),('Ear','AC6025',.84),('Ink','251A18',.60),('Eyes','130F0C',.24),('Cream','FFFBF0',.85),('Blue','4F8EAA',.88),('BlueDark','39768F',.87),('BlueLight','9BC6D0',.86),('Gold','F5CD61',.78),('GoldDark','C9963D',.8),('Mouth','E5A496',.88),('MouthEdge','80462D',.85),('Shoe','2B252A',.60)]:material(n,c,r)

def obj(name,data=None,parent=None,p=(0,0,0),mat=None):
    o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);o.location=p
    if parent:o.parent=parent
    if mat:o.data.materials.append(M[mat])
    parts.append(o);return o
def finish(o,name,mat,parent):
    o.name=name;o.data.materials.append(M[mat]);o.parent=parent
    for f in o.data.polygons:f.use_smooth=True
    parts.append(o);return o
def ellipsoid(name,p,s,mat,parent,segments=24,rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=p)
    o=bpy.context.object;o.scale=s;return finish(o,name,mat,parent)
def rounded(name,p,s,mat,parent,bevel=.06):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.scale=s
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    m=o.modifiers.new('Rounded silhouette','BEVEL');m.width=bevel;m.segments=4
    bpy.ops.object.modifier_apply(modifier=m.name)
    m=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=m.name)
    return finish(o,name,mat,parent)
def curve(name,points,radius,mat,parent):
    c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.resolution_u=6;c.bevel_depth=radius;c.bevel_resolution=2
    s=c.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
    for b,p in zip(s.bezier_points,points):b.co=p;b.handle_left_type='AUTO';b.handle_right_type='AUTO'
    return obj(name,c,parent,mat=mat)
def mesh(name,verts,faces,mat,parent,sub=0):
    m=bpy.data.meshes.new(name);m.from_pydata(verts,[],faces);m.update()
    o=obj(name,m,parent,mat=mat)
    if sub:
        q=o.modifiers.new('Smooth contour','SUBSURF');q.levels=sub
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=q.name)
    for f in o.data.polygons:f.use_smooth=True
    return o
def patch(name,outline,y,mat,parent):
    # A shallow convex front panel. Every feature is geometry, not a pasted face.
    cx=sum(p[0] for p in outline)/len(outline);cz=sum(p[1] for p in outline)/len(outline)
    verts=[(cx,y(cx,cz) if callable(y) else y-.002,cz)]+[(x,y(x,z) if callable(y) else y,z) for x,z in outline]
    return mesh(name,verts,[(0,(i+1)%len(outline)+1,i+1) for i in range(len(outline))],mat,parent)

root=obj('Brown');root['character']='ブラウン / Brown / 布朗';root['source']='https://oshiri-tantei.com/character/?char=char-brown'
root['adaptation']='Unofficial 3D fan reconstruction; not an official production asset.'
body=obj('Body',parent=root,p=(0,0,.60))
torso=obj('Torso',parent=body,p=(0,0,.20))
# The entire body bobs together. A rounded neck overlaps both chest and head,
# including during a head tilt; the head is a child of the chest, never floating.
ellipsoid('CottonShirt',(0,0,.025),(.325,.275,.30),'Cream',torso)
ellipsoid('Neck',(0,0,.28),(.155,.175,.18),'Fur',torso)
rounded('ShirtPlacket',(0,-.275,.005),(.052,.025,.29),'Cream',torso,.012)
for z in [-.06,.05]:ellipsoid('SmallShirtButton',(0,-.294,z),(.015,.009,.016),'Ink',torso,16,8)
# Collar triangles and blue/gold bow retain the compact original outfit.
for side in [-1,1]:
    collar=patch('Collar',[(side*.025,.245),(side*.18,.215),(side*.11,.115)],-.246,'Cream',torso)
    collar.modifiers.new('Collar thickness','SOLIDIFY').thickness=.015
    bow=mesh('BowWing',[(side*.025,-.288,.18),(side*.155,-.291,.235),(side*.15,-.293,.12),(side*.06,-.312,.175)],[(0,1,3),(1,2,3),(2,0,3)],'Blue',torso)
    bow.modifiers.new('Bow thickness','SOLIDIFY').thickness=.022
ellipsoid('BowKnot',(0,-.312,.18),(.050,.034,.049),'Gold',torso)

# Single tailored shorts silhouette, with a small crotch cutout and flared hems.
outline=[(-.29,.68),(.29,.68),(.345,.32),(.075,.32),(.045,.405),(-.045,.405),(-.075,.32),(-.345,.32)]
vs=[(x,y,z-.60) for y in [-.265,.265] for x,z in outline]
fs=[tuple(reversed(range(8))),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]
shorts=mesh('TailoredShorts',vs,fs,'Blue',body)
bevel=shorts.modifiers.new('Soft cloth edges','BEVEL');bevel.width=.05;bevel.segments=4
norm=shorts.modifiers.new('Cloth normals','WEIGHTED_NORMAL')
for side in [-1,1]:
    curve('SuspenderFront',[(side*.19,-.269,-.21),(side*.19,-.274,-.02),(side*.18,-.17,.24)],.030,'Blue',torso)
    curve('SuspenderBack',[(side*.19,.265,-.21),(side*.14,.275,-.01),(side*.18,.15,.24)],.030,'Blue',torso)
    ellipsoid('SuspenderButton',(side*.19,-.287,-.205),(.047,.018,.047),'Gold',torso,24,12)

head=obj('Head',parent=torso,p=(0,0,.55))
# Full cheeks, a rounded back of the skull and a deeper cap read at every angle.
head_rings=[(-.337,.12,.15),(-.315,.30,.285),(-.265,.415,.345),(-.18,.470,.38),(-.07,.485,.39),(.06,.46,.38),(.19,.405,.34),(.285,.32,.275),(.32,.15,.13)]
verts=[];faces=[];N=64
for z,rx,ry in head_rings:
    for i in range(N):
        a=2*math.pi*i/N;x=rx*math.cos(a);y=ry*math.sin(a)
        # Flatten the central front while preserving full, curved cheeks.
        if y<0:y=-ry*(max(0,1-(abs(x)/rx)**3.2)**.34)
        verts.append((x,y,z))
for j in range(len(head_rings)-1):
    for i in range(N):a=j*N+i;b=j*N+(i+1)%N;faces.append((a,b,b+N,a+N))
faces.extend([tuple(reversed(range(N))),tuple((len(head_rings)-1)*N+i for i in range(N))])
mesh('BrownHead',verts,faces,'Fur',head,1)
# Soft drooping dog ears; no upright bear ears or cream muzzle.
for side,label in [(-1,'L'),(1,'R')]:
    ear=obj('Ear'+label,parent=head,p=(side*.415,0,.175))
    e=ellipsoid('FloppyEar'+label,(side*.065,-.015,-.07),(.14,.095,.082),'Ear',ear)
    e.rotation_euler.y=side*.5

for side,label in [(-1,'L'),(1,'R')]:
    eye=obj('Eye'+label,parent=head,p=(side*.247,-.378,.005))
    ellipsoid('Eye',(0,0,0),(.059,.029,.072),'Eyes',eye)
    ellipsoid('EyeGlint',(-.016,-.028,.025),(.010,.004,.013),'Cream',eye,16,8)
    brow=obj('Brow'+label,parent=head,p=(side*.247,-.37,.095))
    curve('Eyebrow',[(-.055,.013,-.005),(0,-.008,.011),(.055,-.008,-.005)],.008,'Ink',brow)
ellipsoid('TinyNose',(0,-.403,-.026),(.019,.012,.012),'Ink',head,20,12)
# Friendly open smile with two small canine teeth.
mouth=[(-.243,-.130),(-.215,-.104),(-.13,-.110),(0,-.128),(.13,-.110),(.215,-.104),(.243,-.130),(.237,-.192),(.19,-.242),(.10,-.267),(0,-.273),(-.10,-.267),(-.19,-.242),(-.237,-.192)]
def face_surface(x,z,bias=.018):
    for i in range(len(head_rings)-1):
        za,xa,ya=head_rings[i];zb,xb,yb=head_rings[i+1]
        if za<=z<=zb:
            t=(z-za)/(zb-za);rx=xa+(xb-xa)*t;ry=ya+(yb-ya)*t
            return -ry*max(0,1-(abs(x)/rx)**3.2)**.34-bias
    return -.39-bias
def smile(parent,outline):
    patch('SmileInterior',outline,face_surface,'Mouth',parent)
    curve('SmileOutline',[(x,face_surface(x,z,.021),z) for x,z in outline+[outline[0]]],.007,'MouthEdge',parent)
    for side in [-1,1]:
        patch('CanineTooth',[(side*.177,-.112),(side*.140,-.119),(side*.157,-.155)],lambda x,z:face_surface(x,z,.027),'Cream',parent)
smile_face=obj('FaceSmile',parent=head);smile(smile_face,mouth)
joy=obj('FaceJoy',parent=head);smile(joy,[(x*1.04,z-.006) for x,z in mouth])
for side in [-1,1]:
    arc=[(side*.247+dx,.01+.035*(1-(dx/.06)**2)) for dx in [-.06,-.03,0,.03,.06]]
    curve('HappyEye',[(x,face_surface(x,z,.024),z) for x,z in arc],.012,'Ink',joy)
surprise=obj('FaceSurprise',parent=head)
oval=[(.067*math.cos(i*math.tau/32),-.185+.068*math.sin(i*math.tau/32)) for i in range(32)]
patch('SurprisedMouth',oval,face_surface,'MouthEdge',surprise)
curve('SurprisedLip',[(x,face_surface(x,z,.024),z) for x,z in oval+[oval[0]]],.006,'Mouth',surprise)
focus=obj('FaceFocus',parent=head)
curve('DeterminedSmile',[(x,face_surface(x,z,.024),z) for x,z in [(-.12,-.172),(-.06,-.188),(0,-.191),(.06,-.188),(.12,-.172)]],.008,'MouthEdge',focus)

# Blue newsboy cap. UV stripes are a packed, exportable 512px plaid texture.
texture=bpy.data.images.new('Brown_BluePlaid',width=512,height=512,alpha=False)
pixels=[]
base=(79/255,142/255,170/255);light=(157/255,196/255,206/255);dark=(62/255,122/255,148/255)
for y in range(512):
    for x in range(512):
        # Longitudinal seams and curved transverse bands follow the cap's UVs.
        u=x%64;v=y%128;c=base
        if u in (31,32) or v in (62,63):c=light
        elif u in (29,30,33,34) or v in (60,61,64,65):c=tuple(.4*a+.6*b for a,b in zip(base,light))
        elif u in (0,1) or v in (0,1):c=dark
        pixels.extend((*c,1))
texture.pixels.foreach_set(pixels);texture.pack()
plaid=M['Blue'].copy();plaid.name='Cap_BluePlaid';M['Plaid']=plaid
nodes=plaid.node_tree.nodes;n=nodes.new('ShaderNodeTexImage');n.image=texture
plaid.node_tree.links.new(n.outputs['Color'],nodes.get('Principled BSDF').inputs['Base Color'])
cap_rings=[(.185,.36,.35),(.23,.445,.42),(.30,.505,.455),(.39,.51,.45),(.48,.465,.415),(.57,.36,.33),(.63,.21,.20),(.655,.015,.018)]
verts=[];faces=[]
for z,rx,ry in cap_rings:
    for i in range(65):
        a=2*math.pi*i/64
        verts.append((rx*math.cos(a),ry*math.sin(a)+.025,z))
for j in range(len(cap_rings)-1):
    for i in range(64):a=j*65+i;faces.append((a,a+1,a+66,a+65))
cap=mesh('NewsboyCap',verts,faces,'Plaid',head)
uv=cap.data.uv_layers.new(name='UVMap')
for poly in cap.data.polygons:
    for li in poly.loop_indices:
        vi=cap.data.loops[li].vertex_index;uv.data[li].uv=(vi%65/64,(vi//65)/(len(cap_rings)-1))
cap.modifiers.new('Soft cap crown','SUBSURF').levels=1
ellipsoid('CapTopButton',(0,.025,.66),(.052,.043,.017),'BlueDark',head,24,12)
# Crescent visor, smoothly dipping over the forehead.
v=[];f=[]
for row in range(4):
    t=row/3
    for i in range(33):
        a=-math.pi*.44+math.pi*.88*i/32
        x=math.sin(a)*(.395+.045*t);y=-math.cos(a)*(.35+.14*t)-.018;z=.222-.070*t+.023*math.cos(a)
        v.append((x,y,z))
for j in range(3):
    for i in range(32):a=j*33+i;f.append((a,a+1,a+34,a+33))
visor=mesh('CapVisor',v,f,'Blue',head)
visor.modifiers.new('Visor thickness','SOLIDIFY').thickness=.025
curve('VisorEdge',[v[3*33+i] for i in range(33)],.008,'BlueDark',head)
curve('CapBand',[(.395*math.sin(a),-.37*math.cos(a),.215) for a in [(-math.pi*.48+i*math.pi*.96/32) for i in range(33)]],.014,'BlueDark',head)

for side,label in [(-1,'L'),(1,'R')]:
    arm=obj('Arm'+label,parent=torso,p=(side*.292,0,.15))
    ellipsoid('UpperSleeve'+label,(side*.028,0,-.07),(.113,.132,.15),'Cream',arm)
    elbow=obj('Elbow'+label,parent=arm,p=(side*.045,0,-.18))
    ellipsoid('LowerSleeve'+label,(0,0,-.035),(.100,.117,.10),'Cream',elbow)
    rounded('Cuff'+label,(0,-.010,-.098),(.18,.21,.065),'Cream',elbow,.026)
    ellipsoid('Paw'+label,(0,-.022,-.165),(.096,.096,.11),'Fur',elbow)
    ellipsoid('Thumb'+label,(-side*.06,-.089,-.154),(.043,.047,.065),'Fur',elbow,24,12)
    curve('PawFold'+label,[(side*.025,-.113,-.17),(-side*.005,-.116,-.18)],.004,'Ear',elbow)
    leg=obj('Leg'+label,parent=body,p=(side*.17,0,-.19))
    ellipsoid('UpperLeg'+label,(0,0,-.065),(.097,.11,.12),'Fur',leg)
    knee=obj('Knee'+label,parent=leg,p=(0,0,-.15))
    ellipsoid('LowerLeg'+label,(0,0,-.06),(.082,.095,.11),'Fur',knee)
    rounded('Sock'+label,(0,-.008,-.145),(.15,.17,.060),'Cream',knee,.02)
    ellipsoid('Shoe'+label,(0,-.06,-.192),(.112,.176,.068),'Shoe',knee)
    rounded('Sole'+label,(0,-.063,-.244),(.205,.30,.027),'Ink',knee,.012)

# Original reference's small yellow shoulder satchel, readable from behind.
curve('BagStrapFront',[(-.225,-.18,.245),(-.07,-.302,.11),(.14,-.294,-.07),(.39,-.04,-.25)],.021,'Gold',torso)
curve('BagStrapBack',[(-.225,.16,.245),(-.075,.292,.08),(.14,.286,-.09),(.39,.15,-.25)],.021,'Gold',torso)
bag=obj('Satchel',parent=torso,p=(.405,.16,-.25))
ellipsoid('SatchelBody',(0,0,0),(.166,.128,.205),'Gold',bag)
rounded('SatchelFlap',(.018,-.081,.06),(.255,.09,.22),'Gold',bag,.06)
curve('SatchelSeam',[(-.10,-.131,.10),(-.085,-.145,-.055),(.04,-.145,-.075),(.13,-.103,.025)],.008,'GoldDark',bag)
ellipsoid('SatchelButton',(.012,-.137,-.035),(.022,.010,.022),'GoldDark',bag,16,8)

# Convert curves and apply export-only construction modifiers. Preserve pivots.
for o in list(parts):
    if o.type=='CURVE':
        bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
        bpy.ops.object.convert(target='MESH')
    if o.type=='MESH':
        bpy.context.view_layer.objects.active=o
        for mod in list(o.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
# Merge rigid geometry per animated pivot, dramatically reducing mobile draw calls.
for parent in [o for o in parts if o.type=='EMPTY']:
    children=[o for o in list(bpy.context.scene.objects) if o.parent==parent and o.type=='MESH']
    if len(children)>1:
        bpy.ops.object.select_all(action='DESELECT')
        for o in children:o.select_set(True)
        bpy.context.view_layer.objects.active=children[0];bpy.ops.object.join();children[0].name=parent.name+'_Mesh'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(OUT/'brown.glb'),export_format='GLB',use_selection=True,export_yup=True,export_apply=True)
triangles=sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons)
stats={'triangles':triangles,'mesh_objects':sum(o.type=='MESH' for o in bpy.context.scene.objects),'materials':len(M),'height_m':2.03,'articulation':['Body','Torso','Head','ArmL','ArmR','ElbowL','ElbowR','LegL','LegR','KneeL','KneeR','EarL','EarR','Satchel'],'expressions':['Smile','Joy','Surprise','Focus'],'body_depth_m':.55,'head_depth_m':.78,'reference':root['source']}
(PREVIEW/'model-stats.json').write_text(json.dumps(stats,indent=2))

# Reusable studio in the .blend; geometry above is exported without this stage.
material('Stage','DFEADF',.9)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.01));ground=bpy.context.object;ground.name='StudioGround';ground.data.materials.append(M['Stage'])
world=bpy.data.worlds.new('StudioWorld');bpy.context.scene.world=world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.27,.32,1);world.node_tree.nodes['Background'].inputs[1].default_value=.45
for name,p,power,size in [('Key',(-3,-4,6),500,4),('Fill',(4,-2,3),250,3),('Rim',(2,4,5),650,3)]:
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size
    o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);o.location=p;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('ModelCamera');camera=bpy.data.objects.new('ModelCamera',d);bpy.context.collection.objects.link(camera);bpy.context.scene.camera=camera
camera.data.type='ORTHO';camera.data.ortho_scale=2.65
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=False
scene.render.resolution_x=608;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard';scene.view_settings.look='Medium High Contrast';scene.view_settings.exposure=0;scene.view_settings.gamma=1
def view(angle):
    a=math.radians(angle);camera.location=(math.sin(a)*5,-math.cos(a)*5,2.1);camera.rotation_euler=(Vector((0,0,1.03))-camera.location).to_track_quat('-Z','Y').to_euler()
view(0)
for expression in [joy,surprise,focus]:
    for child in expression.children:child.hide_render=True;child.hide_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'brown_character.blend'))
if not os.environ.get('BROWN_SKIP_RENDERS'):
    for name,angle in [('01-front',0),('02-three-quarter',-35),('03-side',90),('04-back',180)]:
        view(angle);scene.render.filepath=str(PREVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)
print('BROWN_MODEL',json.dumps(stats))
