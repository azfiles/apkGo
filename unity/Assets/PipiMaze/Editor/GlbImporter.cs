using System;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEditor.AssetImporters;
using UnityEngine;
using UnityEngine.Rendering;

namespace PipiMaze.Editor
{
    // The project's GLBs contain rigid transform hierarchies, uncompressed triangle
    // meshes and embedded PNGs. Keep the authored bytes and import those features
    // explicitly; reject unsupported data rather than silently replacing models.
    [ScriptedImporter(1,"pglb")]
    public sealed class GlbImporter : ScriptedImporter
    {
        [Serializable] class Doc { public Node[] nodes; public Geometry[] meshes; public Accessor[] accessors; public View[] bufferViews; public Mat[] materials; public Image[] images; public Texture[] textures; public Scene[] scenes; public int scene; public string[] extensionsRequired; public Skin[] skins; }
        [Serializable] class Skin { public int[] joints; }
        [Serializable] class Node { public string name; public int mesh=-1; public int[] children; public float[] translation,rotation,scale,matrix; }
        [Serializable] class Geometry { public Primitive[] primitives; }
        [Serializable] class Primitive { public Attributes attributes; public int indices=-1,material=-1,mode=4; }
        [Serializable] class Attributes { public int POSITION=-1,NORMAL=-1,TEXCOORD_0=-1; }
        [Serializable] class Accessor { public int bufferView,byteOffset,componentType,count; public string type; }
        [Serializable] class View { public int byteOffset,byteLength,byteStride; }
        [Serializable] class Mat { public string name; public Pbr pbrMetallicRoughness; public float[] emissiveFactor; }
        [Serializable] class Pbr { public float[] baseColorFactor; public TexRef baseColorTexture; public float roughnessFactor=1; }
        [Serializable] class TexRef { public int index; }
        [Serializable] class Image { public int bufferView=-1; public string name,mimeType; }
        [Serializable] class Texture { public int source; }
        [Serializable] class Scene { public int[] nodes; }
        Doc doc;byte[] bin;
        public override void OnImportAsset(AssetImportContext ctx)
        {
            byte[] bytes=File.ReadAllBytes(ctx.assetPath);
            if(BitConverter.ToUInt32(bytes,0)!=0x46546c67 || BitConverter.ToInt32(bytes,4)!=2)throw new InvalidDataException("Expected GLB 2");
            int length=BitConverter.ToInt32(bytes,12);string metadata="Assets/PipiMaze/Editor/ModelMetadata/"+Path.GetFileNameWithoutExtension(ctx.assetPath)+".json";ctx.DependsOnSourceAsset(metadata);doc=JsonUtility.FromJson<Doc>(File.ReadAllText(metadata));
            int offset=20+length, binaryLength=BitConverter.ToInt32(bytes,offset);bin=new byte[binaryLength];Buffer.BlockCopy(bytes,offset+8,bin,0,binaryLength);
            if(doc.extensionsRequired!=null&&doc.extensionsRequired.Length>0 || doc.skins!=null&&doc.skins.Length>0)throw new InvalidDataException("Unsupported compressed/skinned model");
            var textures=new Texture2D[doc.images?.Length??0];
            for(int i=0;i<textures.Length;i++)
            {
                var source=doc.images[i];var view=doc.bufferViews[source.bufferView];var png=new byte[view.byteLength];Buffer.BlockCopy(bin,view.byteOffset,png,0,png.Length);
                var tex=new Texture2D(2,2,TextureFormat.RGBA32,true){name=source.name??"Texture"};if(!tex.LoadImage(png))throw new InvalidDataException("Invalid embedded texture");
                tex.wrapMode=TextureWrapMode.Repeat;ctx.AddObjectToAsset("texture"+i,tex);textures[i]=tex;
            }
            const string shaderPath="Assets/PipiMaze/Resources/Shaders/Soft.shader";ctx.DependsOnArtifact(shaderPath);var shader=AssetDatabase.LoadAssetAtPath<Shader>(shaderPath);if(!shader)throw new InvalidDataException("Missing Pipi shader");
            var materials=new Material[doc.materials.Length];
            for(int i=0;i<materials.Length;i++)
            {
                Mat source=doc.materials[i];var mat=new Material(shader){name=source.name,enableInstancing=true};var p=source.pbrMetallicRoughness;
                float[] c=p?.baseColorFactor;mat.color=c!=null&&c.Length==4 ? new Color(c[0],c[1],c[2],c[3]).gamma : Color.white;
                int textureIndex=p?.baseColorTexture?.index??-1;
                if(textureIndex>=0){if(doc.textures==null||textureIndex>=doc.textures.Length)throw new InvalidDataException("Invalid material texture index");mat.mainTexture=textures[doc.textures[textureIndex].source];}
                if(source.emissiveFactor!=null&&source.emissiveFactor.Length>=3)mat.SetColor("_Emission",new Color(source.emissiveFactor[0],source.emissiveFactor[1],source.emissiveFactor[2]));
                ctx.AddObjectToAsset("material"+i,mat);materials[i]=mat;
            }
            var meshes=new Mesh[doc.meshes.Length][];
            for(int i=0;i<meshes.Length;i++)
            {
                var primitives=doc.meshes[i].primitives;meshes[i]=new Mesh[primitives.Length];
                for(int j=0;j<primitives.Length;j++)
                {
                    var p=primitives[j];if(p.mode!=4)throw new InvalidDataException("Expected triangles");var positions=Read(p.attributes.POSITION,3);int count=positions.Length/3;
                    var vertices=new Vector3[count];for(int k=0;k<count;k++)vertices[k]=new Vector3(positions[k*3],positions[k*3+1],-positions[k*3+2]);
                    var mesh=new Mesh{name="Mesh"+i+"_"+j,indexFormat=count>65535?IndexFormat.UInt32:IndexFormat.UInt16};mesh.vertices=vertices;
                    var ix=p.indices>=0?Read(p.indices,1):null;var triangles=new int[ix?.Length??count];for(int k=0;k<triangles.Length;k++)triangles[k]=ix!=null?(int)ix[k]:k;
                    for(int k=0;k<triangles.Length;k+=3){int t=triangles[k+1];triangles[k+1]=triangles[k+2];triangles[k+2]=t;}mesh.triangles=triangles;
                    if(p.attributes.NORMAL>=0){var n=Read(p.attributes.NORMAL,3);var ns=new Vector3[count];for(int k=0;k<count;k++)ns[k]=new Vector3(n[k*3],n[k*3+1],-n[k*3+2]);mesh.normals=ns;}else mesh.RecalculateNormals();
                    if(p.attributes.TEXCOORD_0>=0){var uv=Read(p.attributes.TEXCOORD_0,2);var uvs=new Vector2[count];for(int k=0;k<count;k++)uvs[k]=new Vector2(uv[k*2],1-uv[k*2+1]);mesh.uv=uvs;}
                    mesh.RecalculateBounds();ctx.AddObjectToAsset("mesh"+i+"_"+j,mesh);meshes[i][j]=mesh;
                }
            }
            var nodes=new GameObject[doc.nodes.Length];
            for(int i=0;i<nodes.Length;i++)
            {
                var n=doc.nodes[i];if(n.matrix!=null&&n.matrix.Length>0)throw new InvalidDataException("Matrix nodes require explicit conversion");var go=new GameObject(n.name??"Node"+i);nodes[i]=go;
                if(n.translation!=null&&n.translation.Length==3)go.transform.localPosition=new Vector3(n.translation[0],n.translation[1],-n.translation[2]);
                if(n.rotation!=null&&n.rotation.Length==4)go.transform.localRotation=new Quaternion(-n.rotation[0],-n.rotation[1],n.rotation[2],n.rotation[3]);
                if(n.scale!=null&&n.scale.Length==3)go.transform.localScale=new Vector3(n.scale[0],n.scale[1],n.scale[2]);
                if(n.mesh>=0)for(int j=0;j<meshes[n.mesh].Length;j++)
                {
                    var part=new GameObject("Primitive"+j);part.transform.SetParent(go.transform,false);part.AddComponent<MeshFilter>().sharedMesh=meshes[n.mesh][j];var renderer=part.AddComponent<MeshRenderer>();
                    int mi=doc.meshes[n.mesh].primitives[j].material;renderer.sharedMaterial=materials[mi>=0?mi:0];
                }
            }
            for(int i=0;i<nodes.Length;i++)if(doc.nodes[i].children!=null)foreach(int child in doc.nodes[i].children)nodes[child].transform.SetParent(nodes[i].transform,false);
            var root=new GameObject(Path.GetFileNameWithoutExtension(ctx.assetPath));foreach(int n in doc.scenes[doc.scene].nodes)nodes[n].transform.SetParent(root.transform,false);
            ctx.AddObjectToAsset("root",root);ctx.SetMainObject(root);
        }
        float[] Read(int index,int width)
        {
            Accessor a=doc.accessors[index];var v=doc.bufferViews[a.bufferView];int size=a.componentType==5126||a.componentType==5125?4:a.componentType==5123?2:1;
            int stride=v.byteStride>0?v.byteStride:width*size;var values=new float[a.count*width];
            for(int i=0;i<a.count;i++)for(int j=0;j<width;j++)
            {
                int p=v.byteOffset+a.byteOffset+i*stride+j*size;
                values[i*width+j]=a.componentType==5126?BitConverter.ToSingle(bin,p):a.componentType==5125?BitConverter.ToUInt32(bin,p):a.componentType==5123?BitConverter.ToUInt16(bin,p):bin[p];
            }
            return values;
        }
    }
}
