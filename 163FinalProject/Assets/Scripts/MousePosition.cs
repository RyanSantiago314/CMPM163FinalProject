using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MousePosition : MonoBehaviour
{
    Renderer render;

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
    [Range(0, 4)]
    public int DownRes;


    // Start is called before the first frame update
    void Start()
    {
        //render = GetComponent<Renderer>();

        //sets the renderer's shader to 
        //our shader
        //render.material.shader = Shader.Find("Custom/myBlur");

        //lastMousePosition = Vector3.zero;
        //changeInMousePosition = Vector3.zero;
        lastMousePosition = 0f;
        changeInMousePosition = 0f;

        myCam = gameObject.GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        MoveCam();
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


    private void MoveCam()
    {
        //Camera Movement
        xRot += Input.GetAxis("Mouse X");
        yRot -= Input.GetAxis("Mouse Y");

        transform.eulerAngles = new Vector3(yRot * ySpeed, xRot * xSpeed);
    }
}
