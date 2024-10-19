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

			// Ripple parameters
			_RippleWaveLength("Ripple Wave Length", float) = 1.0
			_RippleFrequency("Ripple Frequency", float) = 1.0
			_RippleDecay("Ripple Decay", float) = 1.0
			_RippleAmplitude("Ripple Amplitude", float) = 0.5
			_RippleMaxDistance("Ripple Max Distance", float) = 10.0
			_TimeOffset("Time Offset", float) = 0.0
			_RippleCount("Ripple Count", int) = 0
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

			// Ripple properties
			int _RippleCount;
			float4 _ObjectPositions[10]; // This will be set by the script, not in the Properties block
			float _RippleWaveLength;
			float _RippleFrequency;
			float _RippleDecay;
			float _RippleAmplitude;
			float _RippleMaxDistance;
			float _TimeOffset;

			struct Input
			{
				float2 uv_MainTex;
				float3 worldPos;
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

			// Ripple effect logic
			float CalculateRippleEffect(float3 worldPos, float3 objPos, float time)
			{
				// Calculate the distance from the object's position to the current vertex
				float dist = distance(worldPos, objPos);

				// Wave number (related to ripple wavelength, controls ripple size)
				float waveNumber = 2.0 * UNITY_PI / _RippleWaveLength;

				// Angular frequency (related to ripple speed)
				float angularFrequency = 2.0 * UNITY_PI * _RippleFrequency;

				// Calculate the ripple amplitude falloff based on distance
				float amplitude = _RippleAmplitude * saturate(1.0 - dist / _RippleMaxDistance);  // Amplitude reduces to 0 at max distance

				// Circular ripple effect with decaying amplitude
				float wave = amplitude * sin(waveNumber * dist - angularFrequency * time) * exp(-_RippleDecay * dist);

				return wave;
			}

			void vert(inout appdata_full vertexData)
			{
				float3 p = vertexData.vertex.xyz;
				float3 tangent = float3(1, 0, 0);
				float3 binormal = float3(0, 0, 1);

				// Apply Gerstner waves
				p += GerstnerWave(_WaveA, p, tangent, binormal);
				p += GerstnerWave(_WaveB, p, tangent, binormal);
				p += GerstnerWave(_WaveC, p, tangent, binormal);
				p += GerstnerWave(_WaveD, p, tangent, binormal);
				p += GerstnerWave(_WaveE, p, tangent, binormal);

				float3 normal = normalize(cross(binormal, tangent));

				// Ripple effect
				if (_RippleCount > 0) {

					float rippleEffect = 0.0;
					float time = _TimeOffset + _Time.y;

					for (int i = 0; i < _RippleCount - 1; i++)
					{
						float3 objPos = _ObjectPositions[i].xyz;
						rippleEffect += CalculateRippleEffect(p, objPos, time);
					}

					p.y += rippleEffect; // Apply the ripple displacement
				}

				vertexData.vertex.xyz = p;
				vertexData.normal = normal;
			}

			void surf(Input IN, inout SurfaceOutputStandard o)
			{
				fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;

				o.Albedo = c.rgb;
				o.Metallic = _Metallic;
				o.Smoothness = _Glossiness;
				o.Alpha = c.a;
			}

			ENDCG
		}
			Fallback "Diffuse"
}