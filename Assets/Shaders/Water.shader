Shader "Unlit/Water"
{
	Properties
	{
		_Color("Color", Color) = (1, 1, 1, 1)
		_MainTex("Texture", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0, 1)) = 0.5
		_Metallic("Metallic", Range(0, 1)) = 0.0

			// Gerstner waves
			_WaveA("WaveA: Dir, Steepness, WaveLength", Vector) = (1, 0, 0.5, 10)
			_WaveB("WaveB: Dir, Steepness, WaveLength", Vector) = (0, 1, 0.25, 20)
			_WaveC("WaveC: Dir, Steepness, WaveLength", Vector) = (1, 1, 0.15, 10)
			_WaveD("WaveD: Dir, Steepness, WaveLength", Vector) = (-1, 0, 0.1, 5)
			_WaveE("WaveE: Dir, Steepness, WaveLength", Vector) = (-1, 1, 0.1, 5)

			// Ripple effect properties
			_RippleSize("Ripple Size", Float) = 1.0
			_RippleSpeed("Ripple Speed", Float) = 1.0
			_RippleFrequency("Ripple Frequency", Float) = 1.0

			// Define Ripple Amplitudes in Properties Block
			_RippleAmplitude0("Ripple Amplitude 0", Float) = 0.0
			_RippleAmplitude1("Ripple Amplitude 1", Float) = 0.0
			_RippleAmplitude2("Ripple Amplitude 2", Float) = 0.0
			_RippleAmplitude3("Ripple Amplitude 3", Float) = 0.0
			_RippleAmplitude4("Ripple Amplitude 4", Float) = 0.0
			_RippleAmplitude5("Ripple Amplitude 5", Float) = 0.0
			_RippleAmplitude6("Ripple Amplitude 6", Float) = 0.0
			_RippleAmplitude7("Ripple Amplitude 7", Float) = 0.0
			_RippleAmplitude8("Ripple Amplitude 8", Float) = 0.0
			_RippleAmplitude9("Ripple Amplitude 9", Float) = 0.0
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
			float _RippleSize, _RippleSpeed, _RippleFrequency;
			float _RippleAmplitude0, _RippleAmplitude1, _RippleAmplitude2, _RippleAmplitude3, _RippleAmplitude4, _RippleAmplitude5, _RippleAmplitude6, _RippleAmplitude7, _RippleAmplitude8, _RippleAmplitude9;
			float _OffsetX0, _OffsetX1, _OffsetX2, _OffsetX3, _OffsetX4, _OffsetX5, _OffsetX6, _OffsetX7, _OffsetX8, _OffsetX9;
			float _OffsetZ0, _OffsetZ1, _OffsetZ2, _OffsetZ3, _OffsetZ4, _OffsetZ5, _OffsetZ6, _OffsetZ7, _OffsetZ8, _OffsetZ9;

			struct Input
			{
				float2 uv_MainTex;
				float3 worldPos;  // Pass world position to the surf function
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

				// Apply Gerstner waves
				p += GerstnerWave(_WaveA, p, tangent, binormal);
				p += GerstnerWave(_WaveB, p, tangent, binormal);
				p += GerstnerWave(_WaveC, p, tangent, binormal);
				p += GerstnerWave(_WaveD, p, tangent, binormal);
				p += GerstnerWave(_WaveE, p, tangent, binormal);

				// Offset calculation
				half offsetvert = (vertexData.vertex.x * vertexData.vertex.x) + (vertexData.vertex.z * vertexData.vertex.z);

				// Compute wave values based on the formula in the image
				half value0 = _RippleSize * sin(_Time.w * _RippleSpeed + _RippleFrequency * offsetvert + (vertexData.vertex.x * _OffsetX0) + (vertexData.vertex.z * _OffsetZ0));
				half value1 = _RippleSize * sin(_Time.w * _RippleSpeed + _RippleFrequency * offsetvert + (vertexData.vertex.x * _OffsetX1) + (vertexData.vertex.z * _OffsetZ1));
				half value2 = _RippleSize * sin(_Time.w * _RippleSpeed + _RippleFrequency * offsetvert + (vertexData.vertex.x * _OffsetX2) + (vertexData.vertex.z * _OffsetZ2));
				half value3 = _RippleSize * sin(_Time.w * _RippleSpeed + _RippleFrequency * offsetvert + (vertexData.vertex.x * _OffsetX3) + (vertexData.vertex.z * _OffsetZ3));
				half value4 = _RippleSize * sin(_Time.w * _RippleSpeed + _RippleFrequency * offsetvert + (vertexData.vertex.x * _OffsetX4) + (vertexData.vertex.z * _OffsetZ4));
				half value5 = _RippleSize * sin(_Time.w * _RippleSpeed + _RippleFrequency * offsetvert + (vertexData.vertex.x * _OffsetX5) + (vertexData.vertex.z * _OffsetZ5));
				half value6 = _RippleSize * sin(_Time.w * _RippleSpeed + _RippleFrequency * offsetvert + (vertexData.vertex.x * _OffsetX6) + (vertexData.vertex.z * _OffsetZ6));
				half value7 = _RippleSize * sin(_Time.w * _RippleSpeed + _RippleFrequency * offsetvert + (vertexData.vertex.x * _OffsetX7) + (vertexData.vertex.z * _OffsetZ7));
				half value8 = _RippleSize * sin(_Time.w * _RippleSpeed + _RippleFrequency * offsetvert + (vertexData.vertex.x * _OffsetX8) + (vertexData.vertex.z * _OffsetZ8));
				half value9 = _RippleSize * sin(_Time.w * _RippleSpeed + _RippleFrequency * offsetvert + (vertexData.vertex.x * _OffsetX9) + (vertexData.vertex.z * _OffsetZ9));

				// Apply calculated values to vertex positions
				vertexData.vertex.y += value0 * _RippleAmplitude0;
				vertexData.vertex.y += value1 * _RippleAmplitude1;
				vertexData.vertex.y += value2 * _RippleAmplitude2;
				vertexData.vertex.y += value3 * _RippleAmplitude3;
				vertexData.vertex.y += value4 * _RippleAmplitude4;
				vertexData.vertex.y += value5 * _RippleAmplitude5;
				vertexData.vertex.y += value6 * _RippleAmplitude6;
				vertexData.vertex.y += value7 * _RippleAmplitude7;
				vertexData.vertex.y += value8 * _RippleAmplitude8;
				vertexData.vertex.y += value9 * _RippleAmplitude9;

				// Apply calculated values to normals
				vertexData.normal.y += value0 * _RippleAmplitude0;
				vertexData.normal.y += value1 * _RippleAmplitude1;
				vertexData.normal.y += value2 * _RippleAmplitude2;
				vertexData.normal.y += value3 * _RippleAmplitude3;
				vertexData.normal.y += value4 * _RippleAmplitude4;
				vertexData.normal.y += value5 * _RippleAmplitude5;
				vertexData.normal.y += value6 * _RippleAmplitude6;
				vertexData.normal.y += value7 * _RippleAmplitude7;
				vertexData.normal.y += value8 * _RippleAmplitude8;
				vertexData.normal.y += value9 * _RippleAmplitude9;

				// Calculate the normal using the cross product of the tangent and binormal
				float3 normal = normalize(cross(binormal, tangent));

				vertexData.vertex.xyz = p;
				vertexData.normal = normal;
			}

			void surf(Input IN, inout SurfaceOutputStandard o)
			{
				fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;

				// Add cumulative ripple effect to the color for debugging
				//float rippleValue = AccumulateRippleEffects(IN.worldPos);
				//c.rgb += rippleValue; // Increase brightness to visualize ripples

				o.Albedo = c.rgb;
				o.Metallic = _Metallic;
				o.Smoothness = _Glossiness;
				o.Alpha = c.a;
			}

			ENDCG
		}
			Fallback "Diffuse"
}