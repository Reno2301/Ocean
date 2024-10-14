using System.Collections;
using UnityEngine;

public class Object : MonoBehaviour
{
    private GameObject waterObject;
    private Material waterMaterial;
    private WaveController waveController;

    private Vector4 waveA;
    private Vector4 waveB;
    private Vector4 waveC;

    public Transform[] floaters;
    public float underwaterDrag = 3f;
    public float underwaterAngularDrag = 1f;
    public float airDrag = 0f;
    public float airAngularDrag = 0.05f;
    public float floatingPower = 15f;

    private Rigidbody rb;

    public int floatersUnderWater;
    bool underWater;


    /*    public Transform frontLeftCorner;
        public Transform frontRightCorner;
        public Transform backLeftCorner;
        public Transform backRightCorner;

        private Rigidbody rb;  // Rigidbody for physics (falling and rotation)
        private bool inWater = false;  // Track if the object is in water

        public float buoyancyForce = 10f;  // Controls how quickly the object floats up*/

    public float rippleIntensity = 5f;  // Intensity of the ripple effect when the object hits the water

    void Start()
    {
        waterObject = GameObject.FindGameObjectWithTag("Water");
        waveController = waterObject.GetComponent<WaveController>();

        // Get the material of the water object
        if (waterObject != null)
        {
            waterMaterial = waterObject.GetComponent<Renderer>().material;
        }

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

    // Update the wave parameters from the shader
    void UpdateWaveParameters()
    {
        if (waterMaterial != null)
        {
            waveA = waterMaterial.GetVector("_WaveA");
            waveB = waterMaterial.GetVector("_WaveB");
            waveC = waterMaterial.GetVector("_WaveC");
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

        // Sum the contributions from each wave for the final height.
        return waveAHeight.y + waveBHeight.y + waveCHeight.y;
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
                Vector3 buoyancyForce = Vector3.up * floatingPower * Mathf.Abs(difference);
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

        if (underWater && floatersUnderWater == 0)
        {
            underWater = false;
            SwitchState(false);
        }
    }

    //use air or underwater drag and angulardrag
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

    void OnTriggerEnter(Collider other)
    {
        if (other.gameObject == waterObject)
        {
            // Add a ripple
        }
    }

    void OnTriggerExit(Collider other)
    {
        if (other.gameObject == waterObject)
        {
            // Optionally, you can fade the ripple smoothly
            StartCoroutine(FadeRippleOut());
        }
    }

    // Coroutine to fade out the ripple over time
    private IEnumerator FadeRippleOut()
    {
        yield return new WaitForEndOfFrame();
        //Fade out ripple
    }
}
