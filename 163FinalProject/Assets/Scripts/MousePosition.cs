using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MousePosition : MonoBehaviour
{

    [SerializeField]
    private float lastMousePosition;
    [SerializeField]
    private float changeInMousePosition;

    [SerializeField]
    private float mouseVelocity;

    //Camera attributes
    public Camera myCam;
    private float yRot;
    private float xRot;

    private float ySpeed = 2f;
    private float xSpeed = 2f;


    public Material BlurMaterial;
    [Range(0, 10)]
    public int Iterations;

    private bool isDrunk;
    private bool rotCamera = true;



    // Start is called before the first frame update
    void Start()
    {

        lastMousePosition = 0f;
        changeInMousePosition = 0f;

        myCam = gameObject.GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        MoveCam();

        if (Input.GetKeyDown(KeyCode.F))
        {
            Breathalize();
        }
        if (Input.GetKeyDown(KeyCode.Space))
        {
            rotCamera = !rotCamera;
        }


        //Don't do blur effect unless Drunk
        if (isDrunk == false) return;

        changeInMousePosition = Input.mousePosition.x - lastMousePosition;



        if (Input.mousePosition.x == lastMousePosition && mouseVelocity != 0)
        {
            mouseVelocity -= 10;

            if (mouseVelocity < 500)
            {
                mouseVelocity -= 0f;
            }
            else if (mouseVelocity < 1500)
            {
                mouseVelocity -= 0.2f;
            }
            else
            {
                mouseVelocity -= 10;
            }


        }else if(Input.mousePosition.x == lastMousePosition && mouseVelocity <= 50)
        {
            mouseVelocity = 0f;
        }else if(changeInMousePosition < 20)
        {
            mouseVelocity = 1000f;
        }else if(changeInMousePosition < 100)
        {
            mouseVelocity = 1500f;
        }
        else
        {
            mouseVelocity = 2000f;

        }

        mouseVelocity = Mathf.Clamp(mouseVelocity, 0, 3000);

        Iterations = (int)mouseVelocity / 300;


        lastMousePosition = Input.mousePosition.x;
    }



    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        int width = src.width;
        int height = src.height;

        RenderTexture rt = RenderTexture.GetTemporary(width, height);
        Graphics.Blit(src, rt);

        for (int i = 0; i < Iterations; i++)
        {
            RenderTexture rt2 = RenderTexture.GetTemporary(width, height);
            Graphics.Blit(rt, rt2, BlurMaterial);
            RenderTexture.ReleaseTemporary(rt);
            rt = rt2;
        }

        Graphics.Blit(rt, dst);
        RenderTexture.ReleaseTemporary(rt);
    }

    void Breathalize()
    {
        isDrunk = !isDrunk;
    }

    private void MoveCam()
    {
        if (rotCamera)
        {
            //Camera Movement
            transform.RotateAround(GameObject.Find("Beer").transform.position, Vector3.up, Input.GetAxisRaw("Horizontal"));

            transform.LookAt(GameObject.Find("Beer").transform);
        }
        else
        {
            xRot += Input.GetAxis("Mouse X");
            yRot -= Input.GetAxis("Mouse Y");

            transform.eulerAngles = new Vector3(yRot * ySpeed, xRot * xSpeed);
        }
    }
}
