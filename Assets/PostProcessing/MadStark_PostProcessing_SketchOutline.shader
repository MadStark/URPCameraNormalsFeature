Shader "MadStark/PostProcessing/Sketch Outlines"
{
    Properties 
    {
        [HideInInspector] _MainTex ("Base (RGB)", 2D) = "white" {}
        _NormalsThreshold ("Normals Threshold", Float) = 0.1
        _DepthThreshold ("Depth Threshold", Float) = 0.1
    }
    SubShader 
    {
        Tags { "RenderType"="Opaque" }
        ZWrite Off
        ZTest Always

        Pass
        {
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            TEXTURE2D(_MadCameraNormals);       SAMPLER(sampler_MadCameraNormals);      float4 _MadCameraNormals_TexelSize;
            TEXTURE2D(_MainTex);                SAMPLER(sampler_MainTex);               float4 _MainTex_TexelSize;
            TEXTURE2D(_CameraDepthTexture);     SAMPLER(sampler_CameraDepthTexture);    float4 _CameraDepthTexture_TexelSize;

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv        : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                output.uv = input.uv;

                return output;
            }
            
            float _NormalsThreshold;
            float _DepthThreshold;

            half CalculateOutlineFromCameraNormals(float2 uv)
            {
                half3 normal0 = SAMPLE_TEXTURE2D(_MadCameraNormals, sampler_MadCameraNormals, uv + float2(-1, -1) * _MadCameraNormals_TexelSize.xy).xyz;
                half3 normal1 = SAMPLE_TEXTURE2D(_MadCameraNormals, sampler_MadCameraNormals, uv + float2( 1,  1) * _MadCameraNormals_TexelSize.xy).xyz;
                half3 normal2 = SAMPLE_TEXTURE2D(_MadCameraNormals, sampler_MadCameraNormals, uv + float2( 1, -1) * _MadCameraNormals_TexelSize.xy).xyz;
                half3 normal3 = SAMPLE_TEXTURE2D(_MadCameraNormals, sampler_MadCameraNormals, uv + float2(-1,  1) * _MadCameraNormals_TexelSize.xy).xyz;

                half3 normalFiniteDifference0 = normal1 - normal0;
                half3 normalFiniteDifference1 = normal3 - normal2;

                half edgeNormal = sqrt(dot(normalFiniteDifference0, normalFiniteDifference0) + dot(normalFiniteDifference1, normalFiniteDifference1));
                return step(_NormalsThreshold, edgeNormal);
            }
            
            half CalculateOutlineFromCameraDepth(float2 uv)
            {
                half depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv);

                half depth0 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv + float2(-1, -1) * _CameraDepthTexture_TexelSize.xy);
                half depth1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv + float2( 1,  1) * _CameraDepthTexture_TexelSize.xy);
                half depth2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv + float2( 1, -1) * _CameraDepthTexture_TexelSize.xy);
                half depth3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv + float2(-1,  1) * _CameraDepthTexture_TexelSize.xy);

                return step(_DepthThreshold, ((depth - depth0) + (depth - depth1) + (depth - depth2) + (depth - depth3)) * 50);

//                half depthFiniteDifference0 = depth1 - depth0;
//                half depthFiniteDifference1 = depth3 - depth2;

//                half edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;
//                return step(_DepthThreshold, edgeDepth);
            }

            half4 frag (Varyings input) : SV_Target 
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half3 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).xyz;
                half3 camPos = GetCameraPositionWS();

                //half on = CalculateOutlineFromCameraNormals(input.uv);
                //half od = CalculateOutlineFromCameraDepth(input.uv);
                
                return half4(col, 1);
            }

            #pragma vertex vert
            #pragma fragment frag

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}