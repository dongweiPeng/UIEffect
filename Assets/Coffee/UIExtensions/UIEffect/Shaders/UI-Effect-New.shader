Shader "UI/Hidden/UI-Effect-New"
{
	Properties
	{
		[PerRendererData] _MainTex ("Main Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255

		_ColorMask ("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
		_ParametizedTexture ("_ParametizedTexture", 2D) = "white" {}
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}
		
		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp] 
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest [unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask [_ColorMask]

		Pass
		{
			Name "Default"

		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			
			#pragma multi_compile __ UNITY_UI_ALPHACLIP

			#pragma shader_feature __ GRAYSCALE SEPIA NEGA PIXEL MONO CUTOFF HUE 
			#pragma shader_feature __ ADD SUBTRACT FILL
			#pragma shader_feature __ FASTBLUR MEDIUMBLUR DETAILBLUR

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"
			#include "UI-Effect.cginc"

			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID

				//float2 uv1 : TEXCOORD1;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				float2 texcoord  : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
				
				#if defined (UI_COLOR)
				fixed4 colorFactor : COLOR1;
				#endif

				half param : TEXCOORD2;
			};
			
			fixed4 _Color;
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;
			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			sampler2D _ParametizedTexture;

			half2 UnpackToVec2(float value)
			{
				const int PACKER_STEP = 4096;
				const int PRECISION = PACKER_STEP - 1;
				fixed4 color;

				color.x = (value % PACKER_STEP) / PRECISION;
				value = floor(value / PACKER_STEP);

				color.y = (value % PACKER_STEP) / PRECISION;
				return color;
			}
            
float4 Tex2DBlurringXXX (sampler2D tex, half2 uv, float bound)
{             

                #if FASTBLUR  
                int KERNEL_SIZE = 3;
                #elif MEDIUMBLUR
                int KERNEL_SIZE = 5;
                #elif DETAILBLUR
                int KERNEL_SIZE = 7;
                #else
                int KERNEL_SIZE = 1;
                #endif  
    float4 o = 0;
    float sum = 0;
    float2 uvOffset;
    int size = KERNEL_SIZE/2;
    float weight = 1.0 / (KERNEL_SIZE * KERNEL_SIZE);
    
    for(int x = -size; x <= size; x++)
    {
        for(int y = -size; y <= size; y++)
        {
            uvOffset = uv;
            uvOffset.x += x * _MainTex_TexelSize.x * bound;
            uvOffset.y += y * _MainTex_TexelSize.y * bound;
            //weight = gauss(x, y, _Sigma);
            o += tex2D(tex, uvOffset) * weight;
            //sum += weight;
        }
    }
    //o *= (1.0f / sum);
    return o;
}

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.color = IN.color * _Color;

				OUT.texcoord = UnpackToVec2(IN.texcoord.x);
				OUT.param = IN.texcoord.y;
				
				return OUT;
			}


			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 param1 = tex2D(_ParametizedTexture, float2(0.25, IN.param));
			
				#if PIXEL
				IN.texcoord = round(IN.texcoord * IN.extraFactor.xy) / IN.extraFactor.xy;
				#endif

				#if defined (UI_BLUR)
				half4 color = (Tex2DBlurringXXX(_MainTex, IN.texcoord, param1.y * 2) + _TextureSampleAdd) * IN.color;
				#else
				half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;
				#endif
				color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);

				#ifdef CUTOFF
				clip (color.a - 1 + param1.x * 1.001);
				#elif UNITY_UI_ALPHACLIP
				clip (color.a - 0.001);
				#endif

				#if MONO
				color.rgb = IN.color.rgb;
				color.a = color.a * tex2D(_MainTex, IN.texcoord).a + param1.x * 2 - 1;
				#elif HUE
				color.rgb = shift_hue(color.rgb, IN.extraFactor.x, IN.extraFactor.y);
				#elif defined (UI_TONE) & !CUTOFF
				color = ApplyToneEffect(color, param1.x);
				#endif

				#if defined (UI_COLOR)
				color = ApplyColorEffect(color, IN.colorFactor) * IN.color;
				#endif

				return color;
			}
		ENDCG
		}
	}
}