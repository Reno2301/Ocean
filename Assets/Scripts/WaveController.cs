using UnityEngine;
using System.Collections.Generic;

public class WaveController : MonoBehaviour
{
    public GameObject waterObject;

    public Vector4 waveA;
    public Vector4 waveB;
    public Vector4 waveC;

    private Material waterMaterial;

    // Stores ripple data: position, time, and intensity
    private List<Vector4> ripples = new List<Vector4>();

    void Start()
    {
        if (waterObject != null)
        {
            waterMaterial = waterObject.GetComponent<Renderer>().material;
        }
        SetWaveParameters();
    }

    void Update()
    {
        UpdateRipples();
    }

    void SetWaveParameters()
    {
        if (waterMaterial != null)
        {
            waterMaterial.SetVector("_WaveA", waveA);
            waterMaterial.SetVector("_WaveB", waveB);
            waterMaterial.SetVector("_WaveC", waveC);
        }
    }

    void UpdateRipples()
    {
        if (waterMaterial != null && ripples.Count > 0)
        {
            // Update ripple data in the shader (limited by a max number of ripples)
            for (int i = 0; i < ripples.Count; i++)
            {
                waterMaterial.SetVector($"_Ripple{i}", ripples[i]);
            }
        }
    }

    // This method would be called when an object collides with the water
    public void AddRipple(Vector3 position, float intensity)
    {
        // Store position and time of the ripple
        ripples.Add(new Vector4(position.x, position.z, Time.time, intensity));

        // Limit number of active ripples to prevent performance issues
        if (ripples.Count > 10) ripples.RemoveAt(0);
    }
}
