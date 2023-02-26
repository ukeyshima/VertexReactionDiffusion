Shader "Unlit/VertexReactionDiffusion"
{
    Properties { }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/VertexReactionDiffusion/Shaderes/Common/Struct/ReactionDiffusionParams.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                uint vid : SV_VertexID;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : TEXCOORD1;
            };

            float4 _MainTex_ST;

            StructuredBuffer<ReactionDiffusionParams> _ReactionDiffusionParamsBuffer;

            v2f vert (appdata v)
            {
                ReactionDiffusionParams reactionDiffusionParams = _ReactionDiffusionParamsBuffer[v.vid];
                float c = reactionDiffusionParams.A - reactionDiffusionParams.B;

                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = float4(c, c, c, 1);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = i.color;
                return col;
            }
            ENDCG
        }
    }
}
