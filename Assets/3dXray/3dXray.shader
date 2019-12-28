//Author : Mohammed Iqubal
// www.Polyandcode.com
//MIT license
Shader "PolyAndCode/3dXRay"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0 
        [HDR] _Emission("Emission",Color) = (0,0,0,0)

        [HideInInspector] _ClipPlaneNormal ("Clip Plane Normal",Vector) = (1,1,1,1)
        [HideInInspector] _ClipPlanePos("Clip Plane Pos",Vector) = (1,1,1,1)

        _CrosssectionColor("Crosssection Hightlight",Color) = (1,0,0.77,1)
        _CrosssectionPower("Crosssection Highlight Spread",Range(0,10)) = 1

        _FresnelColor ("Fresnel Color", Color) = (0,1,0,1)
        _FresnelPower("Fresnel Size",Range(0,10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        LOD 200
        Cull off

        
        //Plane Clipping
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows 
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
        #pragma multi_compile THINGY_ON THINGY_OFF

        
        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };

        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float4 _Emission;

        float4 _ClipPlaneNormal;
        float4 _ClipPlanePos;

        float _CrosssectionPower;
        float4 _CrosssectionColor;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            //Determine which side of the plane vertex is
            float3 vertexVector =  IN.worldPos - _ClipPlanePos.xyz;
            float vertexPlaneDot  =  dot(-_ClipPlaneNormal.xyz,vertexVector.xyz);

            //Discard pixels for vertex on other side of plane i.e dot < 0
            clip(vertexPlaneDot); 

            //highlight calcultion on crossection
            float DotClamped = saturate(1 - vertexPlaneDot);

            // TO DO: bool to enable/ disable  hightlight 
            //Now disabling by setting crossSectionHighlight to 0 if power is 0
            float crossSectionHighlight = _CrosssectionPower <= 0 ? 0 :  pow(DotClamped, 11 - _CrosssectionPower); 
            
            fixed4 albedo = tex2D (_MainTex, IN.uv_MainTex) * _Color;

            //albedo and emission based on hightlight value
            o.Albedo =  (1 - crossSectionHighlight) * albedo.rgb ;
            o.Emission = (1- crossSectionHighlight) * _Emission + crossSectionHighlight * _CrosssectionColor;  
            
            o.Metallic = _Metallic ;
            o.Smoothness = _Glossiness ; 
            o.Alpha = albedo.a ; 
        }
        ENDCG

        //Fresnel 
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows alpha:fade
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        struct Input
        {
            float3 worldNormal;
            float3 viewDir;
            float3 worldPos;
            float facing : VFACE;
        };

        float4 _Emission;

        float4 _ClipPlaneNormal;
        float4 _ClipPlanePos;

        float4 _FresnelColor; 
        float _FresnelPower;


        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            //Determine which side of the plane vertex is
            float3 vertexVector =  IN.worldPos - _ClipPlanePos.xyz;
            float vertexPlaneDot  = dot(_ClipPlaneNormal.xyz,vertexVector.xyz);
            clip(vertexPlaneDot);

            //Fresnel Calculation
            float fresnelDot = dot(IN.worldNormal,IN.viewDir);
            fresnelDot =  saturate(1- fresnelDot);

             // TO DO: bool to enable/ disable  fresnel 
            //Now disabling by setting fresnelDot to 0 if power is 0
            fresnelDot =  _FresnelPower <=0 ? 0 : pow(fresnelDot,10 - _FresnelPower);

            //To ignore inside faces since cull is off
            float facing = IN.facing * 0.5 + 0.5;
            
            o.Alpha = fresnelDot * facing;
            o.Emission = _FresnelColor *  fresnelDot;
        }
        
        ENDCG 

    }
    FallBack "Diffuse"
}
