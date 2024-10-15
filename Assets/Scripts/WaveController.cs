using UnityEngine;
using System.Collections.Generic;

public class WaveController : MonoBehaviour
{
    public GameObject waterObject;

    public Vector4 waveA;
    public Vector4 waveB;
    public Vector4 waveC;
    public Vector4 waveD;
    public Vector4 waveE;

    private int rippleNumber;
    public float distanceX, distanceZ;
    public float[] rippleAmplitude = new float[10];
    public float magnitudeDivider;

    Mesh mesh;

    private Material waterMaterial;

    void Start()
    {
        if (waterObject != null)
        {
            waterMaterial = waterObject.GetComponent<Renderer>().material;
        }
        SetWaveParameters();

        mesh = GetComponent<MeshFilter>().mesh;
    }

    void Update()
    {
        for (int i = 0; i < 10; i++)
        {
            float rippleAmplitude = waterMaterial.GetFloat("_RippleAmplitude" + i);
            if (rippleAmplitude > 0)
            {
                if (rippleAmplitude < 0.1f)
                {
                    rippleAmplitude = 0;
                }
                waterMaterial.SetFloat("_RippleAmplitude" + i, rippleAmplitude);
            }
        }
    }

    void SetWaveParameters()
    {
        if (waterMaterial != null)
        {
            waterMaterial.SetVector("_WaveA", waveA);
            waterMaterial.SetVector("_WaveB", waveB);
            waterMaterial.SetVector("_WaveC", waveC);
            waterMaterial.SetVector("_WaveD", waveD);
            waterMaterial.SetVector("_WaveE", waveE);
        }
    }
    void OnTriggerEnter(Collider other)
    {
        if (rippleNumber == 10)
        {
            rippleNumber = 0;
        }
        rippleAmplitude[rippleNumber] = 0;

        distanceX = this.transform.position.x - other.gameObject.transform.position.x;
        distanceZ = this.transform.position.z - other.gameObject.transform.position.z;

        waterMaterial.SetFloat("_OffsetX" + rippleNumber, distanceX / mesh.bounds.size.x);
        waterMaterial.SetFloat("_OffsetZ" + rippleNumber, distanceZ / mesh.bounds.size.z);

        rippleAmplitude[rippleNumber] = other.GetComponent<Rigidbody>().velocity.magnitude * magnitudeDivider;


        //_RippleAmplitude0 til 9 don't change parameter?
        waterMaterial.SetFloat("_RippleAmplitude" + rippleNumber, rippleAmplitude[rippleNumber]);

        rippleNumber++;
    }
}