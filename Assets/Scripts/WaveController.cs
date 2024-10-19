using UnityEngine;
using System.Collections.Generic;
using System.Collections;

public class WaveController : MonoBehaviour
{
    public GameObject waterObject;

    public Vector4 waveA;
    public Vector4 waveB;
    public Vector4 waveC;
    public Vector4 waveD;
    public Vector4 waveE;

    private Material waterMaterial;

    void Start()
    {
        if (waterObject != null)
        {
            waterMaterial = waterObject.GetComponent<Renderer>().material;
        }
        UpdateWavaParameters();
    }

    private void Update()
    {
        UpdateWavaParameters();
    }

    void UpdateWavaParameters()
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
}