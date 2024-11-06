using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class crates : MonoBehaviour
{
    public GameObject[] gameObjects;

    private void Start()
    {
        StartCoroutine(ResetPosition());
    }

    IEnumerator ResetPosition()
    {
        yield return new WaitForSeconds(10f);

        for (int i = 0; i < gameObjects.Length; i++)
        {
            gameObjects[i].transform.position = new Vector3(gameObjects[i].transform.position.x, gameObjects[i].transform.position.y + 20, gameObjects[i].transform.position.z);
        }

        StartCoroutine(ResetPosition());
    }
}
