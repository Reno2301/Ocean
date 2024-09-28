using UnityEngine;

public class CornerBuoyancy : MonoBehaviour
{
    public GameObject waterObject;  // The water object with the Gerstner wave shader
    private Material waterMaterial;

    private Vector4 waveA;
    private Vector4 waveB;
    private Vector4 waveC;

    public Transform frontLeftCorner;
    public Transform frontRightCorner;
    public Transform backLeftCorner;
    public Transform backRightCorner;

    private Rigidbody rb;  // Rigidbody for physics (falling and rotation)
    private bool inWater = false;  // Track if the object is in water

    public float buoyancyForce = 10f;  // Controls how quickly the object floats up

    void Start()
    {
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

        // Disable gravity initially if the object is in the sky
        rb.useGravity = true;

        // Allow rotation on the Y-axis by ensuring constraints are off
        rb.constraints = RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationZ;
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
        Vector3 waveAHeight = GerstnerWave(waveA, position, time);
        Vector3 waveBHeight = GerstnerWave(waveB, position, time);
        Vector3 waveCHeight = GerstnerWave(waveC, position, time);

        return waveAHeight.y + waveBHeight.y + waveCHeight.y;
    }

    void Update()
    {
        // Update the wave parameters from the shader
        UpdateWaveParameters();

        float time = Time.time;

        // Check if the object is already in water
        if (inWater)
        {
            // Get the positions of the corners
            Vector3 frontLeftPos = frontLeftCorner.position;
            Vector3 frontRightPos = frontRightCorner.position;
            Vector3 backLeftPos = backLeftCorner.position;
            Vector3 backRightPos = backRightCorner.position;

            // Get water heights at each corner
            float heightFL = GetWaterHeight(frontLeftPos, time);
            float heightFR = GetWaterHeight(frontRightPos, time);
            float heightBL = GetWaterHeight(backLeftPos, time);
            float heightBR = GetWaterHeight(backRightPos, time);

            // Calculate the average height
            float averageHeight = (heightFL + heightFR + heightBL + heightBR) / 4.0f;

            // Apply buoyancy effect by moving the object toward the water surface
            Vector3 newPosition = transform.position;
            newPosition.y = Mathf.Lerp(transform.position.y, averageHeight, Time.deltaTime * buoyancyForce);

            rb.MovePosition(newPosition);

            // Calculate tilt/rotation based on the heights at the corners
            Vector3 slopeForward = new Vector3(0, (heightFR + heightFL) / 2.0f - (heightBR + heightBL) / 2.0f, Vector3.Distance(frontLeftPos, backLeftPos)).normalized;
            Vector3 slopeRight = new Vector3(Vector3.Distance(frontLeftPos, frontRightPos), (heightFR + heightBR) / 2.0f - (heightFL + heightBL) / 2.0f, 0).normalized;

            // Keep current Y-axis rotation
            Quaternion currentRotation = rb.rotation;

            // Compute new rotation (only tilt, no Y-axis rotation changes)
            Quaternion tiltRotation = Quaternion.LookRotation(slopeForward, Vector3.Cross(slopeRight, slopeForward).normalized);
            Quaternion finalRotation = Quaternion.Euler(tiltRotation.eulerAngles.x, currentRotation.eulerAngles.y, tiltRotation.eulerAngles.z);

            // Apply the new rotation while preserving Y-axis rotation
            rb.MoveRotation(finalRotation);
        }

        // Check if the object has entered the water (i.e., if its Y position is below the water surface)
        float waterHeightAtCenter = GetWaterHeight(transform.position, time);
        if (transform.position.y <= waterHeightAtCenter && !inWater)
        {
            // The object is now in the water
            inWater = true;

            // Disable gravity and let the buoyancy take over
            rb.useGravity = false;
            rb.velocity = Vector3.zero;  // Stop falling velocity when buoyancy takes over
        } else
        {
            inWater = false;

            rb.useGravity = true;            
        }
    }

    // Optional: Detect if the object leaves the water, to re-enable gravity if needed
    void OnTriggerExit(Collider other)
    {
        if (other.gameObject == waterObject)
        {
            // Object has left the water
            inWater = false;
            rb.useGravity = true;  // Re-enable gravity if the object leaves the water
        }
    }
}
