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
            _RippleCenters("Ripple Centers", Vector) = (0, 0, 0, 0) // Up to 10 ripple centers
            _RippleTimes("Ripple Times", Float) = 0.0                 // Time of each ripple impact
            _RippleSize("Ripple Size", Float) = 1.0
            _RippleIntensity("Ripple Intensity", Float) = 1.0
            _RippleFrequency("Ripple Frequency", Float) = 1.0
            _RippleSpeed("Ripple Speed", Float) = 1.0
            _MaxRipples("Max Ripples", Int) = 10 // Maximum number of ripples
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
            //float4 _RippleCenters[10]; // Array of ripple centers (up to 10)
            //float _RippleTimes[10];     // Array of ripple times
            //float _RippleSize;
            //float _RippleIntensity;
            //float _RippleFrequency;
            //float _RippleSpeed;
            //int _MaxRipples;

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

            //// Ripple logic for a single ripple
            //float RippleEffect(float3 worldPos, float2 rippleCenter, float rippleTime)
            //{
            //    float distance = length(worldPos.xz - rippleCenter);
            //    float timeSinceImpact = _Time.y - rippleTime;
            //    float expandingRadius = timeSinceImpact * _RippleSpeed;

            //    if (distance < expandingRadius)
            //    {
            //        float rippleEffect = sin(distance * _RippleFrequency - timeSinceImpact * 2.0 * UNITY_PI) * _RippleIntensity;
            //        rippleEffect *= exp(-distance / _RippleSize); // Attenuate the ripple over distance

            //        return rippleEffect;
            //    }

            //    return 0.0;
            //}

            //// Calculate cumulative effect of all active ripples
            //float AccumulateRippleEffects(float3 worldPos)
            //{
            //    float totalRippleEffect = 0.0;

            //    // Loop over all ripple centers and accumulate their effect
            //    for (int i = 0; i < _MaxRipples; i++)
            //    {
            //        totalRippleEffect += RippleEffect(worldPos, _RippleCenters[i].xy, _RippleTimes[i]);
            //    }

            //    return totalRippleEffect;
            //}

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

                // Apply cumulative ripple effect
                //float rippleValue = AccumulateRippleEffects(p);
                //p.y += rippleValue; // Apply cumulative ripple effect to Y position

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