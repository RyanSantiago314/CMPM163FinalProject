﻿Shader "Custom/Liquid"
{
    Properties
    {
        _Tint("Tint", Color) = (1,1,1,1)
        _MainTex("Texture", 2D) = "white" {}
        _NoiseTex("Noise Texture", 2D) = "white" {}
        _FillAmount("Fill Amount", Range(-5,5)) = 0.0
        [HideInInspector] _WobbleX("WobbleX", Range(-1,1)) = 0.0
        [HideInInspector] _WobbleZ("WobbleZ", Range(-1,1)) = 0.0
        _TopColor("Top Color", Color) = (1,1,1,1)
        _FoamColor("Foam Line Color", Color) = (1,1,1,1)
        _Rim("Foam Line Width", Range(0,0.5)) = 0.0
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimPower("Rim Power", Range(0,10)) = 0.0
    }

        SubShader
        {
            Tags {"Queue" = "Geometry"  "DisableBatching" = "True" "RenderType" = "Transparent" }
            LOD 200

           GrabPass{"_BackgroundTexture"}

           Pass
           {
             Zwrite On
             Cull Off // we want the front and back faces
             AlphaToMask On // transparency

             CGPROGRAM


            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            //#pragma target 3.0

            #include "UnityCG.cginc"

            struct appdata
            {
              float4 vertex : POSITION;
              float2 uv : TEXCOORD0;
              float3 normal : NORMAL;
            };

            struct v2f
            {
               float2 uv : TEXCOORD0;
               UNITY_FOG_COORDS(1)
               float4 vertex : SV_POSITION;
               float4 screenUV : TEXCOORD1;
               float3 normal : COLOR2;
               float fillEdge : TEXCOORD2;
               float3 viewDir : COLOR;
            };

            sampler2D _MainTex, _NoiseTex, _BackgroundTexture;
            samplerCUBE _CubeMap;
            float4 _MainTex_ST;
            float _FillAmount, _WobbleX, _WobbleZ;
            float4 _TopColor, _RimColor, _FoamColor, _Tint;
            float _Rim, _RimPower;

            float4 RotateAroundYInDegrees(float4 vertex, float degrees)
            {
               float alpha = degrees * UNITY_PI / 180;
               float sina, cosa;
               sincos(alpha, sina, cosa);
               float2x2 m = float2x2(cosa, sina, -sina, cosa);
               return float4(vertex.yz , mul(m, vertex.xz)).xzyw;
            }


            v2f vert(appdata v)
            {
               v2f o;

               o.vertex = UnityObjectToClipPos(v.vertex);
               o.uv = TRANSFORM_TEX(v.uv, _MainTex);
               UNITY_TRANSFER_FOG(o,o.vertex);
               // get world position of the vertex
               float3 worldPos = mul(unity_ObjectToWorld, v.vertex.xyz);
               // rotate it around XY
               float3 worldPosX = RotateAroundYInDegrees(float4(worldPos,0),360);
               // rotate around XZ
               float3 worldPosZ = float3 (worldPosX.y, worldPosX.z, worldPosX.x);

               float noiseSample = tex2Dlod(_NoiseTex, float4(v.uv.xy, 0, 0))/2;
               // combine rotations with worldPos, based on sine wave from script
               float3 worldPosAdjusted = worldPos - (worldPosX  * _WobbleX*noiseSample) - (worldPosZ* _WobbleZ*noiseSample);
               // how high up the liquid is
               o.fillEdge = worldPosAdjusted.y + _FillAmount;

               o.screenUV = ComputeGrabScreenPos(o.vertex);
               o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
               o.normal = v.normal;
               return o;
            }

            fixed4 frag(v2f i, fixed facing : VFACE) : SV_Target
            {
                // sample the texture
                fixed4 col = _Tint;
            // apply fog
            UNITY_APPLY_FOG(i.fogCoord, col);

            float refractiveIndex = 3 * (1 + (_WobbleX + _WobbleZ) / 5);
            float3 refractedDir = refract(normalize(i.screenUV), normalize(i.normal), 1.0 / refractiveIndex);

            // rim light
            float dotProduct = 1 - pow(dot(i.normal, i.viewDir), _RimPower);
            float4 RimResult = smoothstep(0.5, 1.0, dotProduct);
            RimResult *= _RimColor;

            // foam edge
            float4 foam = (step(i.fillEdge, 0.5) - step(i.fillEdge, (0.5 - _Rim)));
            float4 foamColored = foam * (_FoamColor * 0.9) * tex2D(_MainTex, i.uv - _WobbleX * _WobbleZ);
            // rest of the liquid
            float4 result = step(i.fillEdge, 0.5) - foam;
            float4 resultColored = result * col * tex2D(_MainTex, refractedDir) * tex2D(_BackgroundTexture, refractedDir);
            // both together, with the texture
            float4 finalResult = resultColored + foamColored;
            finalResult.rgb += RimResult;

            // color of backfaces/ top
            float4 topColor = _TopColor * (foam + result);
            //VFACE returns positive for front facing, negative for backfacing
            return facing > 0 ? finalResult : topColor;

          }
          ENDCG
         }

        }
}