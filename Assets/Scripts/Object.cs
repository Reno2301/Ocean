using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class Object : MonoBehaviour
{
    readonly float waterDensity = ObjectProperties.waterDensity;
    public float density;
    private bool canFloat;

    public Transform[] floaters;

    public float underWaterDrag = 3f;
    public float underWaterAngularDrag = 1f;
    public float airDrag = 0f;
    public float airAngularDrag = 0.05f;
    public float floatingPower = 15f;
    public float waterHeight = 0f;
    int floatersUnderwater;

    Rigidbody rb;
    bool underwater;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();

        if (density > waterDensity)
        {
            canFloat = false;
        }
        else if (density < waterDensity)
        {
            canFloat = true;
        }
    }

    private void FixedUpdate()
    {
        floatersUnderwater = 0;
        for (int i = 0; i < floaters.Length; i++)
        {
            float difference = floaters[i].position.y - waterHeight;

            if (difference < 0)
            {
                if (canFloat)
                {
                    rb.AddForceAtPosition(Vector3.up * floatingPower * Mathf.Abs(difference), floaters[i].position, ForceMode.Force);
                    floatersUnderwater += 1;
                }
                 
                if (!underwater)
                {
                    underwater = true;
                    SwitchState(true);
                }
            }
        }

        if(underwater && floatersUnderwater == 0)
        {
            underwater = false;
            SwitchState(false);
        }
    }

    void SwitchState(bool isUnderwater)
    {
        if (isUnderwater)
        {
            rb.drag = underWaterDrag;
            rb.angularDrag = underWaterAngularDrag;
        }
        else
        {
            rb.drag = airDrag;
            rb.angularDrag = airAngularDrag;
        }
    }
}
