Shader "SnowCoverShader"
{
    Properties
    {
		_AlbedoTex("Albedo", 2D) = "white" {}
        _NormalTex("Normal Map", 2D) = "bump" {}
        _HeightTex("Height Map", 2D) = "grey" {}
        _OcclusionTex("Occlusion Map", 2D) = "white" {}
		_NormalScale("Normal Scale", Float) = 1.0
        _DiffuseIntensity("Diffuse Intensity", Float) = 1.0
        _SnowThickness("SnowThickness", Range(0, 0.1)) = 0.01
        _SnowDirection ("Snow Direction", Vector) = (0, 1, 0, 0)
        _SnowAmount ("Snow Amount", Range(0,1)) = 0.1
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
            #pragma geometry GS_Main
            #pragma fragment PS_Main

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct VS_IN
            {
                float4 vertex           : POSITION; // object-space vertex position
                float3 normal           : NORMAL; // object-space vertex normal
                float4 tangent          : TANGENT; // object-space vertex tangent
                float2 texcoord         : TEXCOORD0; // texture coordinate
            };

            struct VS_OUT {
                float4 uv               : TEXCOORD0; // texture coordinates
                float3 worldPos         : TEXCOORD1; // world-space vertex position
                float3 worldNormal      : TEXCOORD2; // world-space vertex normal
                float4 worldTangent     : TEXCOORD3; // world-space vertex tangent
            };

            #define GS_IN VS_OUT
            struct GS_OUT
            {
                float4 clipPos          : SV_POSITION; // clip-space vertex position
                float4 uv               : TEXCOORD0; // texture coordinates
                float3 worldPos         : TEXCOORD1; // world-space vertex position
                float3 worldNormal      : TEXCOORD2; // world-space vertex normal
                float3 lightDir         : TEXCOORD4;
                float3 viewDir          : TEXCOORD5;
            };

            #define PS_IN GS_OUT
            struct PS_OUT
            {
                float4 color        : SV_Target; // fragment color
            };

            sampler2D _AlbedoTex;
            sampler2D _NormalTex;
            sampler2D _HeightTex;
            sampler2D _OcclusionTex;
            float _NormalScale;
            float _DiffuseIntensity;
            float _SnowThickness;
            float4 _SnowDirection;
            float _SnowAmount;

            VS_OUT VS_Main(VS_IN input)
            {
                VS_OUT output;
                output.uv = input.texcoord.xyxy;
                output.uv = output.uv * 2.0; // arbitrary texture scaling
                output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz + _SnowDirection * _SnowThickness;
                output.worldNormal = UnityObjectToWorldNormal(input.normal);
                output.worldTangent = float4(UnityObjectToWorldDir(input.tangent.xyz), input.tangent.w);
                return output;
            }

            GS_OUT SetupVertex(GS_IN input, float3 worldNormal)
            {
                GS_OUT output;
                output.clipPos = mul(UNITY_MATRIX_VP, float4(input.worldPos, 1));
                output.uv = input.uv;
                output.worldPos = input.worldPos;
                output.worldNormal = worldNormal;
                // lighting calculation in tangent space
				fixed3 worldBinormal = cross(worldNormal, input.worldTangent.xyz) * input.worldTangent.w;
                float3x3 worldToTangent = float3x3(input.worldTangent.xyz, worldBinormal, worldNormal);
                output.lightDir = mul(worldToTangent, _WorldSpaceLightPos0.xyz);
                output.viewDir = mul(worldToTangent, _WorldSpaceLightPos0.xyz);
                return output;
            }

            GS_IN SetupOffsetVertex(GS_IN input)
            {
                GS_IN output = input;
                output.worldPos -= _SnowDirection * _SnowThickness;
                output.uv = output.uv + _SnowDirection.xyxy * _SnowThickness;
                return output;
            }

            float3 CalculateFaceNormal(float3 p1, float3 p2, float3 p3)
            {
                return normalize(cross(p2 - p1, p3 - p1));
            }

            [maxvertexcount(18)]
            void GS_Main(triangle GS_IN inputs[3], inout TriangleStream<GS_OUT> outputStream)
            {
                float3 faceNormal = (inputs[0].worldNormal + inputs[1].worldNormal + inputs[2].worldNormal) / 3;
                float snowCoverage = 1 - (dot(faceNormal, _SnowDirection) + 1.0) * 0.5;
                float snowStrength = snowCoverage < _SnowAmount;
                if (snowStrength <= 0)
                    return;
                GS_IN offsetVerts[3] = {
                    SetupOffsetVertex(inputs[0]),
                    SetupOffsetVertex(inputs[1]),
                    SetupOffsetVertex(inputs[2])
                };
                for (uint i = 0; i < 3; ++i)
                {
                    uint v0 = i;
                    uint v1 = (i + 2) % 3;
                    float3 normal = CalculateFaceNormal(inputs[v0].worldPos, inputs[v1].worldPos, offsetVerts[v1].worldPos);
                    outputStream.Append(SetupVertex(inputs[v0], normal));
                    outputStream.Append(SetupVertex(inputs[v1], normal));
                    outputStream.Append(SetupVertex(offsetVerts[v1], normal));
                    outputStream.Append(SetupVertex(offsetVerts[v0], normal));
                    outputStream.Append(SetupVertex(inputs[v0], normal));
                    outputStream.RestartStrip();
                }
                outputStream.Append(SetupVertex(inputs[0], inputs[0].worldNormal));
                outputStream.Append(SetupVertex(inputs[1], inputs[1].worldNormal));
                outputStream.Append(SetupVertex(inputs[2], inputs[2].worldNormal));
                outputStream.RestartStrip();
            }

            inline float ComputeDiffuseLight(in float3 lightDirection, in float3 surfaceNormal)
            {
                return _DiffuseIntensity * max(0, dot(lightDirection, surfaceNormal));
            }

            inline float3 ComputeAmbientLightColor()
            {
                return UNITY_LIGHTMODEL_AMBIENT.rgb;
            }

            PS_OUT PS_Main(PS_IN input)
            {
                PS_OUT output;

                fixed3 tangentLightDir = normalize(input.lightDir);
                fixed3 tangentViewDir = normalize(input.viewDir);

                fixed4 packedNormal = tex2D(_NormalTex, input.uv.zw);
				fixed3 tangentNormal;

                tangentNormal = UnpackNormal(packedNormal);
				tangentNormal.xy *= _NormalScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                float snowCoverage = 1 - (dot(input.worldNormal, _SnowDirection) + 1.0) * 0.5;

                float snowStrength = snowCoverage < _SnowAmount;
                fixed3 snowColor = tex2D(_AlbedoTex, input.uv).rgb;
                fixed3 albedo = (1 - snowStrength) + snowColor * snowStrength;
				
				fixed3 ambient = ComputeAmbientLightColor() * albedo;
				
				fixed3 diffuse = ComputeDiffuseLight(tangentLightDir, tangentNormal) * _LightColor0.rgb * albedo;

				output.color = fixed4(ambient + diffuse, 1);
                return output;
            }

            ENDHLSL
        }
    }
}