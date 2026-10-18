"""Rounded storybook courtyard modules. Blender 4.3+; exports glTF and source."""
import bpy, math, random
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'maze3d/assets/models'
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
random.seed(28)
M={}
def mat(name,hex,emit=0,metal=0):
    c=tuple(int(hex[i:i+2],16)/255 for i in (0,2,4))
    # Color values converted from sRGB to linear to preserve authored palette.
    c=tuple(v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4 for v in c)
    m=bpy.data.materials.new(name); m.diffuse_color=(*c,1); m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=(*c,1)
    bs.inputs['Roughness'].default_value=.72; bs.inputs['Metallic'].default_value=metal
    if emit: bs.inputs['Emission Color'].default_value=(*c,1); bs.inputs['Emission Strength'].default_value=emit
    M[name]=m
for a in [('stone','B7D1C0'),('edge','D9E4C9'),('dark','719B8C'),('moss','83B878'),('gold','F0C35A'),('bark','A77C55'),('leaf','85C986'),('leaf2','B9D987'),('coat','EDAC52'),('fur','B47945'),('cream','FFF7D9'),('ink','43362B'),('scarf','63C9BA'),('boot','52505A'),('bag','547D78'),('glow','FFF0B0',.6),('rune','87D5D5',.45),('star','FFD34E'),('star_edge','ECAF38'),('pink','ECA799'),('cloud','FFF9E8')]:mat(*a)
objects=[]
def finish(obj,name,m,parent=None):
    obj.name=name
    if m:obj.data.materials.append(M[m])
    if parent:obj.parent=parent
    objects.append(obj)
    return obj
def empty(name,p=(0,0,0),parent=None):
    o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.location=p;return finish(o,name,None,parent)
def box(name,p,s,m,bevel=.05,parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.scale=s
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Soft carved edges','BEVEL');mod.width=bevel;mod.segments=3
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
        mod=o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,name,m,parent)
def sphere(name,p,s,m,parent=None,ico=False):
    if ico:bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=p)
    else:bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=1,location=p)
    o=bpy.context.object;o.scale=s
    if not ico:
        for poly in o.data.polygons:poly.use_smooth=True
    return finish(o,name,m,parent)
def cyl(name,p,r,d,m,vertices=10,parent=None,r2=None):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r,radius2=r if r2 is None else r2,depth=d,location=p)
    return finish(bpy.context.object,name,m,parent)
def torus(name,p,major,minor,m,parent=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=major,minor_radius=minor,major_segments=32,minor_segments=6,location=p)
    return finish(bpy.context.object,name,m,parent)
def export(name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_apply=True)
    for o in objects:o.hide_set(True)
    objects.clear()

root=empty('Pipi')
body=empty('Torso',(0,0,.85),root)
sphere('Parka',(0,0,.15),(.38,.28,.43),'coat',body)
box('CoatSeam',(0,-.275,.12),(.028,.025,.51),'cream',.01,body)
for z in [0,.2,.4]:sphere('Button',(0,-.296,z),(.028,.018,.028),'gold',body)
head=empty('Head',(0,0,1.51),root)
sphere('Hood',(0,.035,0),(.43,.34,.4),'coat',head)
sphere('Face',(0,-.21,.015),(.325,.2,.28),'cream',head)
for x in [-.28,.28]:
    sphere('Ear',(x,.01,.31),(.14,.095,.15),'fur',head)
    sphere('InnerEar',(x,-.063,.32),(.085,.03,.085),'cream',head)
for x in [-.125,.125]:
    sphere('Eye',(x,-.397,.06),(.037,.022,.055),'ink',head)
    sphere('EyeLight',(x-.008,-.417,.077),(.01,.006,.014),'cream',head)
sphere('Muzzle',(0,-.401,-.045),(.13,.075,.09),'fur',head)
sphere('Nose',(0,-.465,-.014),(.047,.028,.032),'ink',head)
scarf=torus('Scarf',(0,0,1.22),.283,.082,'scarf',root)
box('ScarfTail',(.27,.17,1.03),(.16,.07,.45),'scarf',.035,root).rotation_euler[1]=-.3
pack=box('Backpack',(0,.30,1.02),(.48,.22,.53),'bag',.09,root)
box('BagPocket',(0,.43,.97),(.29,.09,.23),'dark',.04,root)
box('BagClasp',(0,.486,1.04),(.10,.022,.07),'gold',.01,root)
for x in [-.2,.2]:box('ShoulderStrap',(x,-.21,1.04),(.055,.04,.32),'bag',.02,root)
for side,sgn in [('L',-1),('R',1)]:
    arm=empty('Arm'+side,(sgn*.36,0,1.15),root)
    sphere('Sleeve'+side,(sgn*.025,0,-.17),(.125,.135,.26),'coat',arm)
    sphere('Paw'+side,(sgn*.035,-.025,-.37),(.12,.12,.13),'fur',arm)
    leg=empty('Leg'+side,(sgn*.18,0,.52),root)
    sphere('Trouser'+side,(0,0,-.15),(.13,.135,.23),'dark',leg)
    box('Boot'+side,(0,-.065,-.37),(.26,.37,.22),'boot',.07,leg)
    box('Sole'+side,(0,-.065,-.47),(.27,.38,.06),'gold',.02,leg)
# Lantern attached to the explorer's backpack, visible from behind.
lan=empty('PackLantern',(.35,.28,.83),root)
cyl('LanternGlass',(0,0,0),.075,.16,'glow',8,lan)
for z in [-.10,.10]:cyl('LanternCap',(0,0,z),.10,.045,'gold',8,lan)
export('pipi_explorer')

for variant in range(3):
    root=empty('RuinsWall')
    box('Foundation',(0,0,.20),(3.98,3.98,.40),'dark',.10,root)
    for z in range(3):
        # Stone courses with visible recessed joints, but a single collision block in game.
        for x in [-1,1]:
            box('CarvedBlock',(x,0,.64+z*.58),(1.95,3.88,.55),'stone' if (z+variant)%2 else 'edge',.10,root)
    box('Coping',(0,0,2.18),(4.03,4.03,.23),'edge',.10,root)
    for k in range(5):
        x=random.uniform(-1.7,1.7);y=random.uniform(-1.7,1.7)
        sphere('Moss',(x,y,2.30),(random.uniform(.25,.65),random.uniform(.25,.6),.10),'moss',root)
    if variant==1:
        for side in [-1,1]:
            box('Inset',(0,side*1.955,1.24),(.68,.025,.78),'dark',.015,root)
            o=box('DiamondRune',(0,side*1.976,1.24),(.23,.025,.23),'rune',.01,root);o.rotation_euler[1]=math.pi/4
    export('wall_'+str(variant))

root=empty('Beacon')
cyl('Base',(0,0,.13),.66,.26,'dark',8,root)
cyl('Plinth',(0,0,.35),.49,.25,'edge',8,root,r2=.43)
cyl('Column',(0,0,.72),.32,.65,'stone',8,root,r2=.26)
cyl('Bowl',(0,0,1.10),.45,.14,'gold',8,root)
for a in range(4):
    t=a*math.pi/2
    box('Fin',(math.cos(t)*.25,math.sin(t)*.25,.82),(.09,.09,.50),'gold',.015,root)
export('beacon')
root=empty('Crystal')
cyl('CrystalCore',(0,0,0),.25,.62,'rune',5,root,r2=0)
cyl('CrystalLower',(0,0,-.43),0,.24,'rune',5,root,r2=.25)
export('crystal')

root=empty('Gate')
box('Step',(0,0,.12),(3.7,1.6,.24),'dark',.1,root)
for side in [-1,1]:
    box('Foot',(side*1.35,0,.35),(.9,.95,.5),'edge',.08,root)
    box('Pillar',(side*1.35,0,1.65),(.62,.67,2.5),'stone',.07,root)
    for z in [.6,2.45]:box('Band',(side*1.35,0,z),(.72,.76,.16),'gold',.03,root)
    box('LightLine',(side*1.35,-.345,1.55),(.10,.025,1.0),'rune',.015,root)
for i in range(9):
    a=math.pi*i/8
    o=box('ArchStone',(math.cos(a)*1.35,0,2.70+math.sin(a)*1.12),(.52,.72,.57),'edge' if i%2==0 else 'stone',.04,root)
    o.rotation_euler[1]=a-math.pi/2
box('Keystone',(0,-.05,3.9),(.6,.85,.6),'gold',.04,root).rotation_euler[1]=math.pi/4
export('portal')

root=empty('Lantern')
cyl('Foot',(0,0,.12),.28,.24,'dark',8,root)
cyl('Post',(0,0,.85),.055,1.55,'gold',8,root)
cyl('LanternBottom',(0,0,1.52),.23,.1,'dark',6,root)
cyl('LuminousGlass',(0,0,1.77),.16,.42,'glow',6,root)
cyl('Roof',(0,0,2.02),.30,.23,'gold',6,root,r2=.04)
for i in range(4):
    a=i*math.pi/2;box('Frame',(math.cos(a)*.17,math.sin(a)*.17,1.77),(.035,.035,.45),'dark',.005,root)
export('lantern')

for variant in range(2):
    root=empty('Tree')
    cyl('Trunk',(0,0,1.8),.27,3.6,'bark',7,root,r2=.13)
    for i in range(5):
        a=i*2.4;z=2.5+i*.35
        o=cyl('Branch',(math.cos(a)*.45,math.sin(a)*.45,z),.12,1.5,'bark',6,root,r2=.025)
        o.rotation_euler=(math.sin(a)*.65,math.cos(a)*.65,0)
        sphere('Canopy',(math.cos(a)*.8,math.sin(a)*.8,z+.65),(.95,.85,.72),'leaf' if variant==0 else 'leaf2',root)
    sphere('Crown',(0,0,4.45),(1.0,.9,.9),'leaf2',root)
    export('tree_'+str(variant))

root=empty('Grass')
for i in range(7):
    a=i*2.4;h=random.uniform(.2,.55);x=math.cos(a)*.14;y=math.sin(a)*.14
    mesh=bpy.data.meshes.new('Blade');mesh.from_pydata([(x-.04,y,0),(x+.04,y,0),(x+math.cos(a)*.16,y+math.sin(a)*.16,h)],[],[(0,1,2)])
    ob=bpy.data.objects.new('Blade',mesh);bpy.context.collection.objects.link(ob);finish(ob,'Blade','moss',root)
for x,y,z in [(-.13,.08,.29),(.17,-.04,.23)]:
    for i in range(5):
        a=i*math.tau/5
        sphere('Petal',(x+math.cos(a)*.055,y+math.sin(a)*.055,z),(.045,.045,.026),'pink' if x<0 else 'cream',root)
    sphere('FlowerCenter',(x,y,z+.02),(.03,.03,.025),'gold',root)
export('grass')

# A real five-point silhouette, thick rounded edge and domed front/back.
# The star stays readable while turning, unlike the old disc-and-ring pickup.
root=empty('Star')
verts=[];faces=[]
for depth,scale in [(-.145,.75),(0,1.0),(.115,.75)]:
    for i in range(10):
        a=i*math.pi/5;r=(.38 if i%2==0 else .18)*scale
        verts.append((math.sin(a)*r,depth,math.cos(a)*r))
verts.extend([(0,-.19,0),(0,.15,0)])
for i in range(10):
    j=(i+1)%10
    faces.extend([(30,j,i),(i,j,j+10,i+10),(i+10,j+10,j+20,i+20),(31,i+20,j+20)])
data=bpy.data.meshes.new('PuffyFivePointStar');data.from_pydata(verts,[],faces);data.update()
star=bpy.data.objects.new('PuffyFivePointStar',data);bpy.context.collection.objects.link(star);finish(star,'PuffyFivePointStar','star',root)
for p in data.polygons:p.use_smooth=True
bevel=star.modifiers.new('Soft candy edge','BEVEL');bevel.width=.018;bevel.segments=3
# Curved highlight sits on the dome and is visible at small screen sizes.
glint=sphere('StarHighlight',(-.086,-.177,.106),(.026,.012,.055),'cream',root);glint.rotation_euler.y=-.4
export('star')

root=empty('Hurdle')
box('RoundedStoneRail',(0,0,.30),(3.96,.64,.60),'stone',.11,root)
box('CreamCoping',(0,0,.61),(3.98,.68,.08),'cream',.035,root)
for x in [-1.65,1.65]:
    box('GoldEndStripe',(x,0,.33),(.13,.66,.59),'gold',.03,root)
for side in [-1,1]:
    box('JumpInset',(0,side*.326,.31),(.45,.018,.24),'dark',.04,root)
    box('JumpArrow',(-.07,side*.341,.34),(.16,.024,.055),'cream',.015,root).rotation_euler.y=-.65
    box('JumpArrow',(.07,side*.341,.34),(.16,.024,.055),'cream',.015,root).rotation_euler.y=.65
export('hurdle')

root=empty('Cloud')
for p,s in [((-.9,0,0),(1.1,.6,.5)),((0,0,.3),(1.15,.7,.82)),((1,0,0),(1.05,.65,.52))]:sphere('CloudPuff',p,s,'cloud',root)
export('cloud')

# A single editable source file containing all separately named model hierarchies.
for o in bpy.context.scene.objects:o.hide_set(False)
for i,o in enumerate([ob for ob in bpy.context.scene.objects if ob.parent is None]):o.location=(i%4*8,i//4*8,0)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'model-source/maze3d/pipi_ruins_library.blend'))
print('MODELS: 14 reusable courtyard glTF assets and Blender source exported')
