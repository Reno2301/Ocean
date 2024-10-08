Shader "Unlit/Water"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("Texture", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0, 1)) = 0.5
        _Metallic("Metallic", Range(0, 1)) = 0.0
        _WaveA("WaveA: Dir, Steepness, WaveLength", Vector) = (1, 0, 0.5, 10)
        _WaveB("WaveB: Dir, Steepness, WaveLength", Vector) = (0, 1, 0.25, 20)
        _WaveC("WaveC: Dir, Steepness, WaveLength", Vector) = (1, 1, 0.15, 10)
        _RippleSize("Ripple Size", Range(5, 50)) = 10
        _RippleFrequency("Ripple Frequency", Range(0.1, 10)) = 2.0
        _RippleSpeed("Ripple Speed", Range(0.1, 5)) = 1.0
        _RippleStartDistance("Ripple Start Distance", Range(0, 10)) = 1.0
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
            float4 _WaveA, _WaveB, _WaveC;
            float4 _Ripple0, _Ripple1, _Ripple2, _Ripple3, _Ripple4, _Ripple5, _Ripple6, _Ripple7, _Ripple8, _Ripple9;
            float _RippleSize;
            float _RippleFrequency;
            float _RippleSpeed;
            float _RippleStartDistance;

            struct Input
            {
                float2 uv_MainTex;
            };

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

            float3 RippleWave(float4 ripple, float3 p, inout float3 tangent, inout float3 binormal)
            {
                float distance = length(float2(p.x, p.z) - ripple.xy);
                float timeSinceImpact = _Time.y - ripple.z;
                float expandingRadius = timeSinceImpact * _RippleSpeed;

                // Calculate the effective distance, adjusted by the start distance.
                float effectiveDistance = max(0, distance - _RippleStartDistance);

                // Apply the ripple if the effective distance is within the expanding radius
                if (effectiveDistance <= expandingRadius)
                {
                    float attenuation = max(0, 1 - (effectiveDistance / _RippleSize));
                    float wave = sin(effectiveDistance * _RippleFrequency - timeSinceImpact * 2.0 * UNITY_PI) * attenuation * ripple.w;

                    float3 displacement = float3(0, wave, 0);

                    tangent += float3(0, wave, 0);
                    binormal += float3(0, wave, 0);

                    return displacement;
                }

                return float3(0, 0, 0);
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

                // Apply ripples
                p += RippleWave(_Ripple0, p, tangent, binormal);
                p += RippleWave(_Ripple1, p, tangent, binormal);
                p += RippleWave(_Ripple2, p, tangent, binormal);
                p += RippleWave(_Ripple3, p, tangent, binormal);
                p += RippleWave(_Ripple4, p, tangent, binormal);
                p += RippleWave(_Ripple5, p, tangent, binormal);
                p += RippleWave(_Ripple6, p, tangent, binormal);
                p += RippleWave(_Ripple7, p, tangent, binormal);
                p += RippleWave(_Ripple8, p, tangent, binormal);
                p += RippleWave(_Ripple9, p, tangent, binormal);

                // Calculate the normal using the cross product of the tangent and binormal
                float3 normal = normalize(cross(binormal, tangent));

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