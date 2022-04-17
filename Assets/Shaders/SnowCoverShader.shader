Shader "SnowCoverShader"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex VS_Main
            #pragma fragment PS_Main

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct VS_IN
            {
                float4 pos          : POSITION;
                float3 normal       : NORMAL;
            };

            struct VS_OUT
            {
                float4 worldPos     : SV_POSITION;
                float3 worldNormal  : TEXCOORD1;
            };

            #define PS_IN VS_OUT
            struct PS_OUT
            {
                float4 color        : SV_Target;
            };

            VS_OUT VS_Main(VS_IN input)
            {
                VS_OUT output;
                output.worldNormal = UnityObjectToWorldNormal(input.normal).xyz;
                output.worldPos = UnityObjectToClipPos(input.pos);
                return output;
            }

            PS_OUT PS_Main(PS_IN input)
            {
                PS_OUT output;

                // Diffuse lighting
                float3 lightDirection = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;
                float3 lightIntensity = max(0, dot(lightDirection, input.worldNormal));
                float3 diffuseLight = lightColor * lightIntensity;

                // Ambient lighting
                float3 ambientLight = unity_AmbientSky.xyz;

                output.color = float4(diffuseLight + ambientLight, 0);
                return output;
            }

            ENDHLSL
        }
    }
}
