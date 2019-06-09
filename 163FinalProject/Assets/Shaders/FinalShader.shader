Shader "Custom/Final" 
{
    Properties
    {
      _Color("Color", Color) = (1,1,1,1)
      _DistortionTex("Distort", 2D) = "black" {}
      _MainTex("Texture", 2D) = "white" {}
      _NoiseTex("Noise Texture", 2D) = "white" {}
      _FillAmount("Fill Amount", Range(-10,10)) = 0.0
      [HideInInspector] _WobbleX("WobbleX", Range(-1,1)) = 0.0
      [HideInInspector] _WobbleZ("WobbleZ", Range(-1,1)) = 0.0
      _TopColor("Top Color", Color) = (1,1,1,1)
      _FoamColor("Foam Line Color", Color) = (1,1,1,1)
      _Rim("Foam Line Width", Range(0,0.5)) = 0.0
      _RimColor("Rim Color", Color) = (1,1,1,1)
      _RimPower("Rim Power", Range(0,10)) = 0.0
      _Cube("Reflection Cubemap", Cube) = "_Skybox" {}
    }

    SubShader
    {

        Tags { "RenderType" = "Transparent" }
        LOD 100

        GrabPass {}

        Pass
        {
            ZWrite On
            Cull Off
            ColorMask 0

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog  
            #pragma target 3.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                half2 texcoord  : TEXCOORD0;
                half4 grabPos : TEXCOORD1;
                float3 viewDir : COLOR;
                float3 normal : COLOR2;
                float fillEdge : TEXCOORD2;
                UNITY_FOG_COORDS(3)
            };

            sampler2D _MainTex, _NoiseTex, _GrabTexture;
            float4 _MainTex_ST;
            float _FillAmount, _WobbleX, _WobbleZ;
            sampler2D _DistortionTex;
            float4 _Color, _TopColor, _RimColor, _FoamColor;
            float _Rim, _RimPower;

            float4 RotateAroundYInDegrees(float4 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, sina, -sina, cosa);
                return float4(vertex.yz, mul(m, vertex.xz)).xzyw;
            }

            v2f vert(appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
                o.normal = v.normal;
                // get world position of the vertex
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex.xyz);
                // rotate it around XY
                float3 worldPosX = RotateAroundYInDegrees(float4(worldPos, 0), 360);
                // rotate around XZ
                float3 worldPosZ = float3 (worldPosX.y, worldPosX.z, worldPosX.x);

                float noiseSample = tex2Dlod(_NoiseTex, float4(v.texcoord.xy, 0, 0));
                // combine rotations with worldPos, based on sine wave from script
                float3 worldPosAdjusted = worldPos + (worldPosX  * _WobbleX*noiseSample*1.2) + (worldPosZ* _WobbleZ*noiseSample*1.2);
                // how high up the liquid is
                o.fillEdge = worldPosAdjusted.y + _FillAmount;
                return o;
            }

            float4 frag(v2f i, fixed facing : VFACE) : SV_Target
            {

                // sample the texture
                fixed4 c = tex2D(_DistortionTex, i.texcoord);
                c = (0.5 - c) * 0.02;

                half orim = dot(normalize(i.viewDir), i.normal);
                half rim = pow(orim, 0.2);

                float3 col = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(i.grabPos + float4(c.r, c.g, 0, 1 - rim)));

                c = float4((col * _Color * 0.65) * rim + (pow(1 - orim, 5) / 3),1);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, c);

                // rim light
                float dotProduct = 1 - pow(dot(i.normal, i.viewDir), _RimPower);
                float4 RimResult = smoothstep(0.5, 1.0, dotProduct);
                RimResult *= _RimColor;

                // foam edge
                float4 foam = (step(i.fillEdge, 0.5) - step(i.fillEdge, (0.5 - _Rim)));
                float4 foamColored = foam * (_FoamColor * 0.9);
                // rest of the liquid

                float4 result = step(i.fillEdge, 0.5) - foam;
                float4 resultColored = result * c;
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