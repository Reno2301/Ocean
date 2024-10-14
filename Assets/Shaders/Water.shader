Shader "Unlit/Water"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("Texture", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0, 1)) = 0.5
        _Metallic("Metallic", Range(0, 1)) = 0.0
           
        //Gerstner waves
        _WaveA("WaveA: Dir, Steepness, WaveLength", Vector) = (1, 0, 0.5, 10)
        _WaveB("WaveB: Dir, Steepness, WaveLength", Vector) = (0, 1, 0.25, 20)
        _WaveC("WaveC: Dir, Steepness, WaveLength", Vector) = (1, 1, 0.15, 10)
        _WaveD("WaveD: Dir, Steepness, WaveLength", Vector) = (-1, 0, 0.1, 5)
        _WaveE("WaveE: Dir, Steepness, WaveLength", Vector) = (-1, 1, 0.1, 5)
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

            //Gerstner wave properties
            float4 _WaveA, _WaveB, _WaveC, _WaveD, _WaveE;

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