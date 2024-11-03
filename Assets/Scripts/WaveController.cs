using UnityEngine;
using System.Collections.Generic;
using System.Collections;
using UnityEngine.UI;

public class WaveController : MonoBehaviour
{
    [Header("References")]
    private GameObject waterObject;
    public List<GameObject> objects = new();  // Objects in the water

    [Header("Waves parameters")]
    public Vector4 waveA;
    public Vector4 waveB;
    public Vector4 waveC;
    public Vector4 waveD;
    public Vector4 waveE;

    public float heightThreshold = 0.2f;
    public float transitionRange = 1f;
    public Color highWaterColor = new(0.8f, 0.9f, 1, 1);

    public Material waterMaterial;
    private bool parametersChanged = false;  // Track when parameters change

    // Splash particle effect
    [Header("Splash Effect")]
    public GameObject splashPrefab;
    private Queue<GameObject> splashPool = new Queue<GameObject>();  // Pool for splash effects
    public int splashPoolSize = 5;  // Pool size
    public float splashDuration = 1.0f;  // Time the splash should be visible

    // Ripple effect
    [Header("Ripple Effect")]
    public ComputeShader rippleCompute;
    public RenderTexture CurrentWaveState, PreviousWaveState, NextWaveState;
    public Vector2Int gridResolution;
    public RenderTexture ObstacleMap;
    public float rippleDispersionFactor = 0.98f;
    public float rippleAmplitude = 0.8f;

    void Start()
    {
        InitializeTexture(ref CurrentWaveState);
        InitializeTexture(ref PreviousWaveState);
        InitializeTexture(ref NextWaveState);
        ObstacleMap.enableRandomWrite = true;
        Debug.Assert(ObstacleMap.width == gridResolution.x && ObstacleMap.height == gridResolution.y);
        Debug.Log("Map Width: " + ObstacleMap.width + ", map Height: " + ObstacleMap.height);
        Debug.Log("Grid Resolution X: " + gridResolution.x + ", Grid Resolution Y: " + gridResolution.y);
        waterMaterial.mainTexture = CurrentWaveState;

        waterObject = gameObject;

        if (waterObject != null)
        {
            // Initialize wave parameters
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

    void InitializeTexture(ref RenderTexture tex)
    {
        tex = new RenderTexture(gridResolution.x, gridResolution.y, 1, UnityEngine.Experimental.Rendering.GraphicsFormat.R16G16B16A16_SNorm);
        tex.enableRandomWrite = true;
        tex.filterMode = FilterMode.Bilinear; // Enable bilinear filtering
        tex.Create();
    }

    private void Update()
    {
        if (parametersChanged)  // Only update if parameters have changed
        {
            SetWaveParameters();
            parametersChanged = false;  // Reset change flag
        }

        UpdateRippleEffect();
    }

    void UpdateRippleEffect()
    {
        // Swap textures for time steps
        Graphics.CopyTexture(CurrentWaveState, PreviousWaveState);
        Graphics.CopyTexture(NextWaveState, CurrentWaveState);

        // Set compute shader parameters
        rippleCompute.SetTexture(0, "CurrentWaveState", CurrentWaveState);
        rippleCompute.SetTexture(0, "PreviousWaveState", PreviousWaveState);
        rippleCompute.SetTexture(0, "NextWaveState", NextWaveState);
        rippleCompute.SetTexture(0, "ObstacleMap", ObstacleMap);

        rippleCompute.SetVector("gridResolution", new Vector2(gridResolution.x, gridResolution.y));
        rippleCompute.SetFloat("waveDispersionFactor", rippleDispersionFactor);

        // Dispatch the compute shader
        rippleCompute.Dispatch(0, gridResolution.x / 8, gridResolution.y / 8, 1);

        // Set the displacement texture on the water material for vertex displacement
        waterMaterial.SetTexture("_RippleHeightTex", NextWaveState);
        waterMaterial.SetFloat("_RippleAmplitude", rippleAmplitude); // Adjust amplitude as needed
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

    private void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.CompareTag("Object"))
        {
            if (!objects.Contains(other.gameObject))
            {
                objects.Add(other.gameObject);
                parametersChanged = true;  // Mark parameters as changed

                // Trigger splash effect at the point of impact
                TriggerSplash(other.transform.position);

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
