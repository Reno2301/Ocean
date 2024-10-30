using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerMovement : MonoBehaviour
{
    private Object obj;
    private Rigidbody rb;
    public float turnSpeed = 30f;
    public float speed = 10f;

    private void Start()
    {
        obj = GetComponent<Object>();
        rb = GetComponent<Rigidbody>();
    }
    // Update is called once per frame
    void Update()
    {
        transform.Rotate(0f, turnSpeed * Input.GetAxis("Horizontal") * Time.deltaTime, 0f, Space.World);

        if (obj.floatersUnderWater >= 1)
        {
            rb.AddForce(transform.up * speed * Input.GetAxis("Vertical"));
        }
    }
}
