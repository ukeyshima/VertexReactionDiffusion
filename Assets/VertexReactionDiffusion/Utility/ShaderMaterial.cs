using System;
using UnityEngine;

namespace VertexReactionDiffusion.Utility
{
    [Serializable]
    public class ShaderMaterial : IDisposable
    {
        [SerializeField] private Shader _shader;

        private Material _material;

        public Material Material { get => _material;}

        public void Init()
        {
            _material = new Material(_shader);
        }

        public void Dispose()
        {
            UnityEngine.Object.Destroy(_material);
        }
    }
}