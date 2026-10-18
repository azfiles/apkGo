using System;
using UnityEngine;
using UnityEngine.EventSystems;

namespace PipiMaze
{
    public sealed class PointerControl : MonoBehaviour,IPointerDownHandler,IPointerUpHandler,IDragHandler
    {
        public Action<PointerEventData> Down,Drag,Up;int pointer=int.MinValue;
        public void OnPointerDown(PointerEventData e){if(pointer!=int.MinValue)return;pointer=e.pointerId;Down?.Invoke(e);}
        public void OnDrag(PointerEventData e){if(e.pointerId==pointer)Drag?.Invoke(e);}
        public void OnPointerUp(PointerEventData e){if(e.pointerId!=pointer)return;pointer=int.MinValue;Up?.Invoke(e);}
        void OnDisable(){if(pointer!=int.MinValue){pointer=int.MinValue;Up?.Invoke(null);}}
    }
}
