using System;
using System.IO;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace PipiMaze.Editor
{
    public static class UnityBuild
    {
        const string ScenePath="Assets/PipiMaze/Scenes/Maze.unity";
        [MenuItem("Pipi Maze/Configure Unity preview")]
        public static void Configure()
        {
            PlayerSettings.companyName="PipiMaze";PlayerSettings.productName="灯火遗迹 Unity 试玩";PlayerSettings.bundleVersion="0.1.0";
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Android,"com.alex.pipimaze.unitypreview");
            PlayerSettings.defaultInterfaceOrientation=UIOrientation.LandscapeLeft;PlayerSettings.defaultScreenWidth=1280;PlayerSettings.defaultScreenHeight=720;
            PlayerSettings.colorSpace=ColorSpace.Linear;PlayerSettings.runInBackground=false;
            PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android,false);
            PlayerSettings.SetGraphicsAPIs(BuildTarget.Android,new[]{UnityEngine.Rendering.GraphicsDeviceType.OpenGLES3});
            PlayerSettings.Android.minSdkVersion=AndroidSdkVersions.AndroidApiLevel26;PlayerSettings.Android.targetSdkVersion=AndroidSdkVersions.AndroidApiLevel35;
            PlayerSettings.Android.targetArchitectures=AndroidArchitecture.ARM64|AndroidArchitecture.X86_64;
            int version;PlayerSettings.Android.bundleVersionCode=int.TryParse(Argument("-androidVersionCode"),out version)&&version>=100001?version:100001;
            PlayerSettings.Android.forceInternetPermission=false;PlayerSettings.SetScriptingBackend(NamedBuildTarget.Android,ScriptingImplementation.IL2CPP);
            PlayerSettings.SetApiCompatibilityLevel(NamedBuildTarget.Android,ApiCompatibilityLevel.NET_Standard);
            var objects=AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset");if(objects.Length>0){var settings=new SerializedObject(objects[0]);var input=settings.FindProperty("activeInputHandler");if(input!=null){input.intValue=0;settings.ApplyModifiedPropertiesWithoutUndo();}}
            EditorSettings.serializationMode=SerializationMode.ForceText;
            if(!File.Exists(ScenePath)){var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);new GameObject("Pipi Maze Unity").AddComponent<MazeApp>();EditorSceneManager.SaveScene(scene,ScenePath);}
            EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene(ScenePath,true)};AssetDatabase.SaveAssets();
        }
        public static void VerifyAssets()
        {
            int chapters=0;foreach(string id in Level.Ids){var asset=Resources.Load<TextAsset>("Levels/"+id);if(!asset)throw new BuildFailedException("Missing chapter: "+id);var level=JsonUtility.FromJson<Level>(asset.text);level.Validate();chapters++;}
            int models=0;foreach(var data in JsonUtility.FromJson<ModelCatalog>(Resources.Load<TextAsset>("catalog").text).assets)
            {
                var model=Resources.Load<GameObject>("Models/"+data.name);if(!model||model.GetComponentsInChildren<MeshRenderer>(true).Length==0)throw new BuildFailedException("GLB import failed: "+data.name);models++;
            }
            Debug.Log("PIPI_ASSETS_PASS: "+chapters+" authored chapters, "+models+" imported model hierarchies");
        }
        [MenuItem("Pipi Maze/Build Android preview")]
        public static void Android()
        {
            Configure();VerifyAssets();EditorUserBuildSettings.buildAppBundle=false;
            string path=Argument("-customBuildPath")??"Builds/Android/Pipi-Maze-Unity-0.1.0.apk";Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path)));
            var report=BuildPipeline.BuildPlayer(new BuildPlayerOptions{scenes=new[]{ScenePath},locationPathName=path,target=BuildTarget.Android,options=BuildOptions.None});
            if(report.summary.result!=BuildResult.Succeeded)throw new BuildFailedException("Unity Android build failed: "+report.summary.totalErrors+" errors");Debug.Log("PIPI_BUILD_PASS: "+report.summary.outputPath);
        }
        static string Argument(string key){var args=Environment.GetCommandLineArgs();for(int i=0;i<args.Length-1;i++)if(args[i]==key)return args[i+1];return null;}
    }
}
