Shader "Doctrina/Glass" {
	//входные параметры в материал, не факт, что используются в шейдере
    Properties {
      _Color ("Color", Color) = (1,1,1,1)
      _MainTex ("Distort", 2D) = "black" {}
      _Cube ("Reflection Cubemap", Cube) = "_Skybox" {}
    }

    SubShader {
      
      Tags { "RenderType"="Transparent" }
      LOD 100

      Pass{
        ZWrite On
        ColorMask 0
      }

      GrabPass {}          

      CGPROGRAM     
      #pragma surface surf No vertex:vert alpha
      #pragma target 3.5
      #pragma debug

      half4 LightingNo (SurfaceOutput s, half3 lightDir, half atten) {    
            half4 c; 		
    		c.rgb = s.Albedo;
     		c.a = s.Alpha;
     		return c;
	 }

      sampler2D _GrabTexture; 
      samplerCUBE _Cube;

      struct Input {
          	float2 uv_MainTex;
          	float3 viewDir;
			float4 grabUV;
       		float3 worldRefl;
       		float3 worldNormal;    
      };

      sampler2D _MainTex; 
      float4 _Color;


    void vert (inout appdata_full v, out Input o) {
        UNITY_INITIALIZE_OUTPUT(Input,o);
        float4 hpos = UnityObjectToClipPos (v.vertex);
        o.grabUV = ComputeGrabScreenPos(hpos);
    }

      
      void surf (Input IN, inout SurfaceOutput o) {
      	  
      	  float4 c = tex2D (_MainTex, IN.uv_MainTex);
          c = ( 0.5-c ) * 0.02;

          fixed4 reflcol = texCUBE (_Cube, IN.worldRefl);

          half orim = dot ( normalize(IN.viewDir), o.Normal);
          half rim = pow(orim,0.2);
          			
		  float3 col = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(IN.grabUV + float4(c.r,c.g,0,1-rim)));
           		      	  
      	  o.Albedo = (col * _Color * 0.65 +  reflcol * reflcol * 0.1 ) * rim + (pow(1-orim,5) / 3);
      	
  		  o.Alpha = 1;          
      }
      
      ENDCG
    } 
    Fallback "Diffuse" //если шейдер не поддерживается, то выберется этот
  }