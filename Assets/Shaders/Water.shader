Shader "Unlit/Water"
{
	Properties
	{
		_Color("Color", Color) = (1, 1, 1, 1)
		_MainTex("Texture", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0, 1)) = 0.5
		_Metallic("Metallic", Range(0, 1)) = 0.0

			// Gerstner waves
			_WaveA("WaveA: Dir, Steepness, WaveLength", Vector) = (0, 0, 0, 0)
			_WaveB("WaveB: Dir, Steepness, WaveLength", Vector) = (0, 0, 0, 0)
			_WaveC("WaveC: Dir, Steepness, WaveLength", Vector) = (0, 0, 0, 0)
			_WaveD("WaveD: Dir, Steepness, WaveLength", Vector) = (0, 0, 0, 0)
			_WaveE("WaveE: Dir, Steepness, WaveLength", Vector) = (0, 0, 0, 0)

			// New property for color change based on height
			_HeightThreshold("Height Threshold", float) = 1.0
			_TransitionRange("Transition Range", float) = 0.5 // How gradual the transition should be
			_HighWaterColor("High Water Color", Color) = (0.8, 0.9, 1, 1)

			// Ripple parameters
			_RippleHeightTex("Ripple Height Texture", 2D) = "white" {}
			_RippleAmplitude("Ripple Amplitude", Float) = 0.8
	}

		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 100

			CGPROGRAM
			#pragma surface surf Standard fullforwardshadows vertex:vert addshadow
			#pragma target 3.0

			sampler2D _MainTex;
			half _Glossiness;
			half _Metallic;
			fixed4 _Color;

			// Gerstner wave properties
			float4 _WaveA, _WaveB, _WaveC, _WaveD, _WaveE;

			// New properties for color change based on height
			float _HeightThreshold;
			float _TransitionRange;
			fixed4 _HighWaterColor;

			// Properties for ripple
			sampler2D _RippleHeightTex;
			float _RippleAmplitude;

			struct Input
			{
				float2 uv_MainTex;
				float3 worldPos;
				float2 uv_WaveHeightTex;
			};

			// Gerstner wave logic
			float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal)
			{
				float steepness = wave.z;
				float wavelength = wave.w;
				float k = 2 * UNITY_PI / wavelength;
				float c = sqrt(9.8 / k);
				float2 d = normalize(wave.xy);
				float f = k * (dot(d, p.xz) - c * _Time.y);
				float a = steepness / k;

				float3 displacement = float3(
					d.x * (a * cos(f)),
					a * sin(f),
					d.y * (a * cos(f))
				);

				tangent += float3(
					-d.x * d.x * steepness * sin(f),
					d.x * steepness * cos(f),
					-d.x * d.y * steepness * sin(f)
				);

				binormal += float3(
					-d.x * d.y * steepness * sin(f),
					d.y * steepness * cos(f),
					-d.y * d.y * steepness * sin(f)
				);

				return displacement;
			}

			void vert(inout appdata_full vertexData)
			{
				float3 p = vertexData.vertex.xyz;
				float3 tangent = float3(1, 0, 0);
				float3 binormal = float3(0, 0, 1);

				// Apply Gerstner waves as the base displacement
				p += GerstnerWave(_WaveA, p, tangent, binormal);
				p += GerstnerWave(_WaveB, p, tangent, binormal);
				p += GerstnerWave(_WaveC, p, tangent, binormal);
				p += GerstnerWave(_WaveD, p, tangent, binormal);
				p += GerstnerWave(_WaveE, p, tangent, binormal);

				// Sample the ripple height texture for additional displacement on top of Gerstner waves
				float waveHeight = tex2Dlod(_RippleHeightTex, float4(vertexData.texcoord.xy, 0, 0)).r;
				float displacement = waveHeight * _RippleAmplitude * 10;

				// Offset vertex y-position by the ripple height
				p.y += displacement;

				// Calculate normal by sampling neighboring heights in the ripple texture
				float waveHeightRight = tex2Dlod(_RippleHeightTex, float4(vertexData.texcoord.xy + float2(0.01, 0), 0, 0)).r * _RippleAmplitude;
				float waveHeightUp = tex2Dlod(_RippleHeightTex, float4(vertexData.texcoord.xy + float2(0, 0.01), 0, 0)).r * _RippleAmplitude;

				// Calculate tangent vectors based on ripple displacement for accurate normals
				float3 tangentX = float3(1, waveHeightRight - displacement, 0);
				float3 tangentZ = float3(0, waveHeightUp - displacement, 1);

				// Calculate the normal based on the combined displacement
				float3 normal = normalize(cross(binormal + tangentZ, tangent + tangentX));

				// Apply the final position and normal to the vertex
				vertexData.vertex.xyz = p;
				vertexData.normal = normal;
			}


			void surf(Input IN, inout SurfaceOutputStandard o)
			{
				fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;

				c.rgb = float3(0.0, 0.3, 0.6);

				// Gradually transition to the high water color based on height
				float heightFactor = smoothstep(_HeightThreshold, _HeightThreshold + _TransitionRange, IN.worldPos.y);

				// Blend the base color with the high water color using the height factor
				c.rgb = lerp(c.rgb, _HighWaterColor.rgb, heightFactor);

				o.Albedo = c.rgb;
				o.Metallic = _Metallic;
				o.Smoothness = _Glossiness;
				o.Alpha = c.a;
			}

			ENDCG
		}
			Fallback "Diffuse"
}