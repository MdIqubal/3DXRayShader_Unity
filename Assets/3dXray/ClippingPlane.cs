using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ClippingPlane : MonoBehaviour
{
    public Material material;

    void Update()
    {
        if(material == null){
            return;
        }
        material.SetVector("_ClipPlaneNormal",new Vector4(transform.up.x,transform.up.y,transform.up.z,1));
        material.SetVector("_ClipPlanePos",new Vector4(transform.position.x,transform.position.y,transform.position.z,1));
    }
}
