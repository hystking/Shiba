﻿Shader "Dog/Shiba"
{
    Properties
    {
        [Header(Color)]
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _MarbleColor1("Marble Color 1", Color) = (0.7, 0.5, 0.3, 1)
        _MarbleColor2("Marble Color 2", Color) = (0.7, 0.5, 0.3, 1)
        _MarbleColor1Threshold("Marble Color 1 Threshold", range(0, 1)) = 0.4
        _MarbleColor2Threshold("Marble Color 2 Threshold", range(0, 1)) = 0.6
        _MarbleColorFrequency("Marble Color Frequency", range(1, 24)) = 1
        _BaseThreshild("Base Threshold", Range(0, 1)) = 0.78
        _MarbleThreshild("Marble Threshold", Range(0, 1)) = 0.45
        _FadeNoiseAmount("Fade Noise Amount", Range(0, 1)) = 1
        _FadeNoiseFrequency("Fade Noise Frequency", Range(1, 24)) = 4
        [Header(Fur)]
        _FurFrequency("Fur Frequency", Range(64, 512)) = 256
        _FurLayers("Fur Layers", Range(0, 20)) = 16
        _FurLength("Fur Length", Range(0, 0.1)) = 0.025
        _FurAmount("Fur Amount", Range(0, 1)) = 0.5
        _FurDecay("Fur Decay", Range(0, 1)) = 1
        _FurShade("Fur Shade", Range(0, 1)) = 0.3
        [Header(Fur Effect)]
        _FurHardness("Fur Hardness", Range(1, 8)) = 2
        _FurGravity("Fur Gravity", Range(0, 1)) = 0.5
        _WindAmount("Wind Amount", Range(0, 2)) = 0.2
        _WindFrequency("Wind Frequency", Range(0, 8)) = 0.5
        _WindSpeed("Wind Speed", Range(0, 1)) = 0.2
    }
    
    SubShader
    {
        Tags { 
            "Queue" = "AlphaTest"
            "RenderType" = "TransparentCutout"
        }
        LOD 100
		Pass
		{
			Tags{ "LightMode" = "Deferred" }
            
            CGPROGRAM

            #pragma require geometry
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "UnityGlobalIllumination.cginc"
            #include "SimplexNoise3D.hlsl"
            #include "Shiba.hlsl"
            
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}