Shader "SnowCoverShader"
{
    Properties
    {
        _Color ( "Color", Color ) = (1,1,1,1)
        _Gloss ( "Gloss", Float ) = 1
    }
    SubShader
    {
        Tags {
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM

            #pragma vertex VS_Main
            #pragma fragment PS_Main

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct VS_IN
            {
                float4 vertex       : POSITION;
                float3 normal       : NORMAL;
            };

            struct VS_OUT
            {
                float4 clipPos      : SV_POSITION;
                float4 worldPos     : TEXCOORD0;
                float3 localNormal  : TEXCOORD1;
                float3 worldNormal  : TEXCOORD2;
            };

            #define PS_IN VS_OUT
            struct PS_OUT
            {
                float4 color        : SV_Target;
            };

            float4 _Color;
            float _Gloss;

            VS_OUT VS_Main(VS_IN input)
            {
                VS_OUT output;
                output.clipPos = UnityObjectToClipPos(input.vertex);
                output.worldPos = mul(unity_ObjectToWorld, input.vertex);
                output.localNormal = input.normal;
                output.worldNormal = UnityObjectToWorldNormal(input.normal).xyz;
                return output;
            }

            PS_OUT PS_Main(PS_IN input)
            {
                PS_OUT output;
                float3 normal = normalize(input.worldNormal);

                // Direct diffuse lighting
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;
                float lightFalloff = max(0, dot(lightDir, normal));
                float3 directDiffuseLight = lightColor * lightFalloff;

                // Ambient lighting
                float3 ambientLight = unity_AmbientSky.xyz;

                // Specular light
                float3 camPos = _WorldSpaceCameraPos;
                float3 viewDir = normalize(camPos - input.worldPos);
                float3 viewReflect = reflect(-viewDir, normal);
                float specularFalloff = max(0, dot(viewReflect, lightDir));
                // Apply gloss
                specularFalloff = pow(specularFalloff, _Gloss);
                float directSpecular = lightColor * specularFalloff;

                float3 diffuseLight = ambientLight + directDiffuseLight;
                float3 finalColor = diffuseLight * _Color.rgb + directSpecular;
                output.color = float4(finalColor, 0.5);
                return output;
            }

            ENDHLSL
        }
    }
}
