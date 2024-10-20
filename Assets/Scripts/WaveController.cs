using UnityEngine;
using System.Collections.Generic;
using System.Collections;

public class WaveController : MonoBehaviour
{
    public GameObject waterObject;
    public List<GameObject> objects = new();  // Objects in the water
    private readonly Vector4[] objectPositions = new Vector4[10];  // Max 10 positions for now

    public Vector4 waveA;
    public Vector4 waveB;
    public Vector4 waveC;
    public Vector4 waveD;
    public Vector4 waveE;

    public float rippleWaveLength;
    public float rippleFrequency;
    public float rippleDecay;
    public float rippleAmplitude;
    public float rippleMaxDistance;
    public int rippleCount;

    public float heightThreshold = 0.2f;
    public float transitionRange = 1f;
    public Color highWaterColor = new(0.8f, 0.9f, 1, 1);

    private Material waterMaterial;
    private bool parametersChanged = false;  // Track when parameters change

    // Splash particle effect
    public GameObject splashPrefab;
    private Queue<GameObject> splashPool = new Queue<GameObject>();  // Pool for splash effects
    public int splashPoolSize = 5;  // Pool size
    public float splashDuration = 1.0f;  // Time the splash should be visible

    void Start()
    {
        if (waterObject != null)
        {
            waterMaterial = waterObject.GetComponent<Renderer>().material;

            // Initialize ripple and wave parameters
            SetRippleParameters();
            SetWaveParameters();
        }

        // Initialize splash pool
        for (int i = 0; i < splashPoolSize; i++)
        {
            GameObject splash = Instantiate(splashPrefab);
            splash.SetActive(false);  // Initially, all splashes are inactive
            splashPool.Enqueue(splash);  // Add them to the pool
        }
    }

    private void Update()
    {
        if (parametersChanged)  // Only update if parameters have changed
        {
            SetRippleParameters();
            SetWaveParameters();
            parametersChanged = false;  // Reset change flag
        }

        // Update object positions in the water (for ripples) if objects have moved
        UpdateObjectPositions();
    }

    void SetRippleParameters()
    {
        if (waterMaterial != null)
        {
            waterMaterial.SetFloat("_RippleWaveLength", rippleWaveLength);
            waterMaterial.SetFloat("_RippleFrequency", rippleFrequency);
            waterMaterial.SetFloat("_RippleDecay", rippleDecay);
            waterMaterial.SetFloat("_RippleAmplitude", rippleAmplitude);
            waterMaterial.SetFloat("_RippleMaxDistance", rippleMaxDistance);
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
            waterMaterial.SetFloat("_HeightThreshold", heightThreshold);
            waterMaterial.SetFloat("_TransitionRange", transitionRange);
            waterMaterial.SetColor("_HighWaterColor", highWaterColor);
        }
    }

    void UpdateObjectPositions()
    {
        bool positionsUpdated = false;
        int objectCount = Mathf.Min(objects.Count, objectPositions.Length);  // Ensure we don't exceed array size

        // Sort objects based on distance from the camera or some priority logic
        objects.Sort((a, b) => Vector3.Distance(Camera.main.transform.position, a.transform.position)
                               .CompareTo(Vector3.Distance(Camera.main.transform.position, b.transform.position)));

        // Update object positions only when there are changes and limit to the array size
        for (int i = 0; i < objectCount; i++)
        {
            if (objects[i] != null && objectPositions[i] != (Vector4)objects[i].transform.position)
            {
                objectPositions[i] = objects[i].transform.position;
                positionsUpdated = true;
            }
        }

        // Reset any unused slots to Vector4.zero to avoid ghost ripples
        for (int i = objectCount; i < objectPositions.Length; i++)
        {
            if (objectPositions[i] != Vector4.zero)
            {
                objectPositions[i] = Vector4.zero;
                positionsUpdated = true;  // Flag positions as updated if changes were made
            }
        }

        // Only update the shader if positions have changed
        if (positionsUpdated && waterMaterial != null)
        {
            waterMaterial.SetVectorArray("_ObjectPositions", objectPositions);
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.CompareTag("Object"))
        {
            if (!objects.Contains(other.gameObject))
            {
                objects.Add(other.gameObject);
                rippleCount += 1;
                waterMaterial.SetInt("_RippleCount", rippleCount);
                parametersChanged = true;  // Mark parameters as changed

                // Trigger splash effect at the point of impact
                TriggerSplash(other.transform.position);

            }
        }
    }

    private void OnTriggerExit(Collider other)
    {
        if (other.gameObject.CompareTag("Object"))
        {
            if (objects.Remove(other.gameObject))  // Remove and return true if successfully removed
            {
                rippleCount -= 1;
                waterMaterial.SetInt("_RippleCount", rippleCount);
                parametersChanged = true;  // Mark parameters as changed
            }
        }
    }

    void TriggerSplash(Vector3 position)
    {
        // Get a splash from the pool
        GameObject splash = GetSplashFromPool();
        splash.transform.position = position;
        splash.SetActive(true);

        // Deactivate splash after a short duration
        StartCoroutine(DeactivateSplash(splash, splashDuration));
    }

    GameObject GetSplashFromPool()
    {
        if (splashPool.Count > 0)
        {
            return splashPool.Dequeue();
        }
        else
        {
            // If the pool is empty, create a new splash
            return Instantiate(splashPrefab);
        }
    }

    IEnumerator DeactivateSplash(GameObject splash, float delay)
    {
        yield return new WaitForSeconds(delay);
        splash.SetActive(false);  // Hide the splash
        splashPool.Enqueue(splash);  // Return it to the pool
    }
}
