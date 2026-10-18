using System.Text.Json;
using PipiMaze;

int checks=0;
void Check(bool value,string message){checks++;if(!value)throw new Exception(message);}
string assets=Path.GetFullPath(args.Length>0?args[0]:"unity/Assets/PipiMaze/Resources");
foreach(string id in Level.Ids)
{
    var level=JsonSerializer.Deserialize<Level>(File.ReadAllText(Path.Combine(assets,"Levels",id+".json")),new JsonSerializerOptions{IncludeFields=true});level.Validate();
    Check(level.id==id,"chapter identity");
    var objectives=new List<Cell>(level.beacons);objectives.AddRange(level.motes);objectives.Add(level.goal);
    foreach(var objective in objectives){var route=level.Path(level.start,objective);Check(route.Count>0,"reachable objective");Cell previous=level.start;foreach(Cell c in route){Check(level.Open(c),"route stays on a passage");Check(Math.Abs(c.x-previous.x)+Math.Abs(c.y-previous.y)==1,"route uses cardinal edges");previous=c;}}
    for(int y=0;y<level.Width;y++)for(int x=0;x<level.Width;x++)
    {
        var cell=new Cell(x,y);if(level.Open(cell)&&!cell.Equals(level.start))Check(level.Path(level.start,cell).Count>0,"all authored passages reachable");
        float worldX=(x-level.Width/2)*4,worldZ=-(y-level.Width/2)*4;Check((int)MathF.Round(worldX/4)+level.Width/2==x && (int)MathF.Round(-worldZ/4)+level.Width/2==y,"reflected coordinate round trip");
    }
    foreach(var c in level.challenges){Check(6.8f*6.8f/(2*18)>c.height+.15f,"jump clears hurdle with margin");Check(3.25f*(2*6.8f/18)>c.span+.6f,"walking jump crosses gap with capsule margin");Check(level.Hazard(c.cell)!=null,"challenge lookup");}
    for(int i=0;i<level.motes.Length;i++)Check(level.Elevated(i)==level.elevated_motes.Contains(i),"elevated star lookup");
    Cell originalGoal=level.goal;level.goal=new Cell(0,0);bool invalid=false;try{level.Validate();}catch(InvalidOperationException){invalid=true;}Check(invalid,"reject objective inside a wall");level.goal=originalGoal;
}
foreach(string path in Directory.GetFiles(Path.Combine(assets,"../Editor/ModelMetadata"),"*.json"))
{
    using var parsed=JsonDocument.Parse(File.ReadAllText(path));var model=parsed.RootElement;
    foreach(var node in model.GetProperty("nodes").EnumerateArray())
    {
        Check(node.TryGetProperty("mesh",out _),"explicit absent-mesh sentinel");
        Check(node.GetProperty("translation").GetArrayLength()==3&&node.GetProperty("rotation").GetArrayLength()==4&&node.GetProperty("scale").GetArrayLength()==3,"explicit transform defaults");
    }
    foreach(var material in model.GetProperty("materials").EnumerateArray())
    {
        var pbr=material.GetProperty("pbrMetallicRoughness");Check(pbr.GetProperty("baseColorFactor").GetArrayLength()==4,"explicit linear material color");
        int texture=pbr.GetProperty("baseColorTexture").GetProperty("index").GetInt32();Check(texture>=-1&&(texture==-1||texture<model.GetProperty("textures").GetArrayLength()),"explicit absent-texture sentinel");
        Check(material.GetProperty("emissiveFactor").GetArrayLength()==3,"explicit emissive default");
    }
}
Console.WriteLine($"PASS: {checks} Unity maze rules, authored level and model-import contract checks; four chapters.");
