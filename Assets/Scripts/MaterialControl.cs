using UnityEngine;

public class MaterialControl : MonoBehaviour
{
    [SerializeField] private Material _material;

    public void SetSnowThickness(float value)
    {
        this._material.SetFloat("_SnowThickness", value);
    }

    public void SetSnowAmount(float value)
    {
        this._material.SetFloat("_SnowAmount", value);
    }
}
