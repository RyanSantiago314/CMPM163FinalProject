using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Slide : MonoBehaviour
{
    float timer = 0;
    float rock = 0;
    // Start is called before the first frame update
    void Start()
    {
        transform.position = new Vector3(-8.5f, -9.06f, -.03f);
    }

    // Update is called once per frame
    void Update()
    {
        if (timer < 1)
        {
            if (timer < 1 && timer < .5)
                timer += .05f;
            else if (timer < 1 && timer < .75)
                timer += .02f;
            else if (timer < 1 && timer < .87)
                timer += .01f;
            else if (timer < 1)
                timer += .005f;
            transform.position = Vector3.Lerp(new Vector3(-9f, -9.06f, -.03f), new Vector3(10f, -9.06f, -.03f), timer);
            rock -= .27f;
            Quaternion newRot = new Quaternion();
            newRot.eulerAngles = new Vector3(0, 0, rock);
            transform.rotation = newRot;
        }

        if (timer >= 1 && rock < 0)
        {
            rock += .7f;
            Quaternion newRot = new Quaternion();
            newRot.eulerAngles = new Vector3(0, 0, rock);
            transform.rotation = newRot;
            transform.position = new Vector3(transform.position.x - .02f, transform.position.y, transform.position.z);
        }

    }
}
