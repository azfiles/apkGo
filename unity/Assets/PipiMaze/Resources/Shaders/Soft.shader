Shader "Pipi/Soft" {
 Properties { _Color("Color",Color)=(1,1,1,1) _MainTex("Texture",2D)="white"{} _Emission("Emission",Color)=(0,0,0,0) _Occluder("Camera cutaway",Float)=0 }
 SubShader {
  Tags {"RenderType"="Opaque"} LOD 150 Cull Off
  CGPROGRAM
  #pragma surface surf Wrap vertex:vert addshadow fullforwardshadows
  #pragma target 3.0
  #pragma multi_compile_instancing
  sampler2D _MainTex; fixed4 _Color,_Emission; float _Occluder; float4 _Hero;
  struct Input {float2 uv_MainTex;float3 worldPos;};
  void vert(inout appdata_full v) {}
  half4 LightingWrap(SurfaceOutput s,half3 lightDir,half atten) {half d=dot(s.Normal,lightDir)*0.65+0.35;return half4(s.Albedo*_LightColor0.rgb*(max(0,d)*atten),s.Alpha);}
  void surf(Input IN,inout SurfaceOutput o) {
   #if !defined(UNITY_PASS_SHADOWCASTER)
   if(_Occluder>0.5 && _Hero.w>0.5) {
    float3 ray=_WorldSpaceCameraPos-_Hero.xyz;float t=saturate(dot(IN.worldPos-_Hero.xyz,ray)/max(dot(ray,ray),0.001));
    if(t>0.06 && t<0.98)clip(distance(IN.worldPos,_Hero.xyz+ray*t)-1.3);
   }
   #endif
   fixed4 c=tex2D(_MainTex,IN.uv_MainTex)*_Color;o.Albedo=c.rgb;o.Alpha=1;o.Emission=_Emission.rgb;
  }
  ENDCG
 }
 Fallback "Diffuse"
}
