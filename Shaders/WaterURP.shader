Shader "Custom/WaterURP"
{
    Properties
    {
        [NoScaleOffset] _Displacement1Tex ("Displacement 1", 2D) = "white" {}
        [NoScaleOffset] _Displacement2Tex ("Displacement 2", 2D) = "white" {}
        _DisplacementScale ("Displacement Scale", Range(0.0, 0.2)) = 0.1
        _ReflectionYOffset ("Reflection Y Offset", Range(-1.0, 1.0)) = 0
        _ReflectionYScale ("Reflection Y Scale", Range(0.0, 3.0)) = 1
        _Saturate("Saturate", Range(0.0, 1.0)) = 0.5
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Speed("Speed", Float) = 0.5
        _Frequency("Frequency", Float) = 1
        _PixelSize("Pixel Size", Range(1.0, 16.0)) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "Universal"
        }

        Pass
        {
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            ZTest LEqual
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            struct VertexInput
            {
                half4 vertex : POSITION;
                half2 uv : TEXCOORD0;
            };

            struct VertexOutput
            {
                half4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
            };

            sampler2D _Displacement1Tex;
            sampler2D _Displacement2Tex;

            half _DisplacementScale;
            half _ReflectionYOffset;
            half _ReflectionYScale;
            half _Saturate;
            half _Speed;
            half _Frequency;
            int _PixelSize;
            half4 _Color;

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            half2 pixelate(half2 uv, half pixelSize)
            {
                int iSize = int(pixelSize);
                return floor(uv * _ScreenParams / iSize) / _ScreenParams * iSize;
            }

            half4 frag(VertexOutput i) : SV_Target
            {
                half2 uv = i.uv;
                
                half2 displacementUV = uv * _Frequency + half2(_Time.x * _Speed, 0.0);
                half2 displacement1 = tex2D(_Displacement1Tex, displacementUV).rg;
                half2 displacement2 = tex2D(_Displacement2Tex, displacementUV).rg;

                half2 displacement = (displacement1 * _DisplacementScale + displacement2) * _DisplacementScale;

                half2 reflectedUVs = half2(uv.x, saturate(1.0 - _ReflectionYScale * (uv.y + _ReflectionYOffset)));
                half2 screenUVs = pixelate(reflectedUVs + displacement, _PixelSize);

                half4 screenColor = half4(SampleSceneColor(screenUVs).rgb, 1.0);
                half saturation = (1.0 - _Saturate) * screenColor.r;
                screenColor = lerp(screenColor, _Color * half4(saturation, saturation, saturation, 1), saturation);
                return screenColor;
            }
            ENDHLSL
        }
    }
}