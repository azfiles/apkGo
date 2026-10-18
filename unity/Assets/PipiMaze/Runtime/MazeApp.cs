using UnityEngine;

namespace PipiMaze
{
    public sealed class MazeApp : MonoBehaviour
    {
        void Start()
        {
            var world=gameObject.AddComponent<MazeWorld>();world.Initialize();
            var ui=gameObject.AddComponent<MazeUi>();ui.Initialize(world);
            world.Build(Mathf.Clamp(PlayerPrefs.GetInt("pipi.chapter",0),0,3));ui.ShowHome();
        }
    }
}
