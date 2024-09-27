using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class Object : MonoBehaviour
{
    readonly float waterDensity = ObjectProperties.waterDensity;
    public float density;
    private bool canFloat;

    Rigidbody rb;

    public float depthBefSub;

    public float displacement;

    public int floaters;

    public float waterDrag;
    public float waterAngularDrag;

    private void Start()
    {

    }

    private void FixedUpdate()
    {
        
    }
}
