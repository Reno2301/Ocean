using UnityEngine;
using System.Collections.Generic;

public class Object : MonoBehaviour
{
    public Material waterMaterial;

    private Vector4 waveA;
    private Vector4 waveB;
    private Vector4 waveC;
    private Vector4 waveD;
    private Vector4 waveE;

    public Transform[] floaters; // Points where buoyancy is applied
    public float underwaterDrag = 3f;
    public float underwaterAngularDrag = 1f;
    public float airDrag = 0f;
    public float airAngularDrag = 0.05f;
    private float floatingPower;

    private Rigidbody rb;

    public int floatersUnderWater;
    bool underWater;

    void Start()
    {
        floatingPower = gameObject.GetComponent<Rigidbody>().mass * 7;

        // Get the Rigidbody component for falling and rotation
        rb = GetComponent<Rigidbody>();

        if (rb == null)
        {
            // If no Rigidbody exists, add one
            rb = gameObject.AddComponent<Rigidbody>();
        }

        // Enable gravity initially if the object is in the sky
        rb.useGravity = true;
    }

    void UpdateWaveParameters()
    {
        if (waterMaterial != null)
        {
            waveA = waterMaterial.GetVector("_WaveA");
            waveB = waterMaterial.GetVector("_WaveB");
            waveC = waterMaterial.GetVector("_WaveC");
            waveD = waterMaterial.GetVector("_WaveD");
            waveE = waterMaterial.GetVector("_WaveE");
        }
    }

    // Calculate Gerstner wave displacement at a specific point
    Vector3 GerstnerWave(Vector4 wave, Vector3 point, float time)
    {
        float steepness = wave.z;
        float wavelength = wave.w;
        float k = 2 * Mathf.PI / wavelength;
        float c = Mathf.Sqrt(9.8f / k);  // Wave speed
        Vector2 d = new Vector2(wave.x, wave.y).normalized;
        float f = k * (Vector2.Dot(d, new Vector2(point.x, point.z)) - c * time);
        float a = steepness / k;  // Amplitude

        return new Vector3(
            d.x * (a * Mathf.Cos(f)),
            a * Mathf.Sin(f),
            d.y * (a * Mathf.Cos(f))
        );
    }

    // Calculate the water height at a specific position
    public float GetWaterHeight(Vector3 position, float time)
    {
        // Update the wave parameters from the shader
        UpdateWaveParameters();

        // Calculate the height using the same Gerstner wave formulas.
        Vector3 waveAHeight = GerstnerWave(waveA, position, time);
        Vector3 waveBHeight = GerstnerWave(waveB, position, time);
        Vector3 waveCHeight = GerstnerWave(waveC, position, time);
        Vector3 waveDHeight = GerstnerWave(waveD, position, time);
        Vector3 waveEHeight = GerstnerWave(waveE, position, time);

        // Sum the contributions from each wave for the final height.
        return waveAHeight.y + waveBHeight.y + waveCHeight.y + waveDHeight.y + waveEHeight.y;
    }

    void FixedUpdate()
    {
        float time = Time.time;
        floatersUnderWater = 0;

        for (int i = 0; i < floaters.Length; i++)
        {
            // Calculate the difference between floater height and water height at its position
            float waterHeight = GetWaterHeight(floaters[i].position, time);
            float floaterHeight = floaters[i].position.y;
            float difference = floaterHeight - waterHeight;

            // If floater is below water, apply buoyancy force
            if (difference < 0)
            {
                // Calculate the upward buoyancy force proportional to how far under water it is
                Vector3 buoyancyForce = Vector3.up * floatingPower;
                rb.AddForceAtPosition(buoyancyForce, floaters[i].position, ForceMode.Force);

                // Increment the number of floaters under water
                floatersUnderWater++;

                if (!underWater)
                {
                    underWater = true;
                    SwitchState(true);
                }
            }
        }

        // Switch drag and angular drag depending on whether the object is underwater
        if (underWater && floatersUnderWater == 0)
        {
            underWater = false;
            SwitchState(false);
        }
    }

    // Apply the appropriate drag depending on whether the object is underwater
    void SwitchState(bool isUnderwater)
    {
        if (isUnderwater)
        {
            rb.drag = underwaterDrag;
            rb.angularDrag = underwaterAngularDrag;
        }
        else
        {
            rb.drag = airDrag;
            rb.angularDrag = airAngularDrag;
        }
    }
}
