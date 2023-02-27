using System.Runtime.InteropServices;
using VertexReactionDiffusion.Utility;
using UnityEngine;

namespace VertexReactionDiffusion
{
    public class VertexReactionDiffusion : MonoBehaviour
    {
        [SerializeField] private ComputeShader _computeShader;
        [SerializeField] private Mesh _mesh;
        [SerializeField] private ShaderMaterial _renderer;
        [SerializeField] private float _vertexDistanceScale = 2500;
        [SerializeField] private float _smoothLength = 0.003f;
        [SerializeField] private float _diffusionRateA = 1f;
        [SerializeField] private float _diffusionRateB = 0.5f;
        [SerializeField] private float _feed = 0.037f;
        [SerializeField] private float _kill = 0.062f;
        [SerializeField] private float _deltaTime = 1.0f;
        [SerializeField] private float _initialBScale = 0.001f;
        [SerializeField] private Vector2 _initialBPoint = new Vector2(0.02f, 0.11f);

        private int _vertexNum;
        private Vector3Int _gridNum;
        private Vector3 _gridAreaMin;
        private Vector3 _gridSize;
        private GraphicsBuffer _vertexBuffer;
        private GraphicsBuffer _gridIndexBuffer;
        private GraphicsBuffer _gridIndexReferenceBuffer;
        private GraphicsBuffer _reactionDiffusionParamsBuffer;
        private GraphicsBuffer _densityBuffer;

        private Struct.GridIndex[] _gridIndexArray;

        private void Start()
        {
            _vertexNum = _mesh.vertexCount;

            Bounds vertexBounds = _mesh.bounds;

            _renderer.Init();

            int gridIndexBufferNum = (int)Mathf.Pow(2, Mathf.Ceil(Mathf.Log(_vertexNum, 2)));

            _gridSize = new Vector3(_smoothLength, _smoothLength, _smoothLength);
            _gridNum = new Vector3Int((int)(vertexBounds.size.x / _gridSize.x) + 1, (int)(vertexBounds.size.y / _gridSize.y) + 1, (int)(vertexBounds.size.z / _gridSize.z) + 1);
            _gridAreaMin = vertexBounds.min;
            _gridIndexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, gridIndexBufferNum, Marshal.SizeOf(typeof(Struct.GridIndex)));
            _gridIndexReferenceBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, _gridNum.x * _gridNum.y * _gridNum.z, Marshal.SizeOf(typeof(Struct.GridIndexReference)));
            _reactionDiffusionParamsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, _vertexNum, Marshal.SizeOf(typeof(Struct.ReactionDiffusionParams)));
            _vertexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, _vertexNum, Marshal.SizeOf(typeof(Vector3)));
            _densityBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, _vertexNum, Marshal.SizeOf(typeof(float)));

            _vertexBuffer.SetData(_mesh.vertices);

            _gridIndexArray = new Struct.GridIndex[_gridIndexBuffer.count];
            for(int i = 0; i < _gridIndexArray.Length; i++) _gridIndexArray[i] = new Struct.GridIndex(){Index = int.MaxValue};

            _gridIndexBuffer.SetData(_gridIndexArray);

            Kernel kernel = new Kernel(_computeShader, "Init");
            _computeShader.SetFloat("_InitialBScale", _initialBScale);
            _computeShader.SetVector("_InitialBPoint", _initialBPoint);
            _computeShader.SetBuffer(kernel.Index, "_ReactionDiffusionParamsBuffer", _reactionDiffusionParamsBuffer);
            _computeShader.SetBuffer(kernel.Index, "_VertexBuffer", _vertexBuffer);
            _computeShader.Dispatch(kernel.Index, _vertexNum / kernel.ThreadNumX + 1, 1, 1);
        }

        private void Update()
        {
            _computeShader.SetInts("_GridNum", new int[]{_gridNum.x, _gridNum.y, _gridNum.z});
            _computeShader.SetVector("_GridAreaMin", _gridAreaMin);
            _computeShader.SetVector("_GridSize", _gridSize);
            _computeShader.SetInt("_VertexNum", _vertexNum);
            _computeShader.SetInt("_GridIndexReferenceBufferLength", _gridIndexReferenceBuffer.count);
            _computeShader.SetFloat("_VertexDistanceScale", _vertexDistanceScale);
            _computeShader.SetFloat("_SmoothLength", _smoothLength);
            _computeShader.SetFloat("_DiffusionRateA", _diffusionRateA);
            _computeShader.SetFloat("_DiffusionRateB", _diffusionRateB);
            _computeShader.SetFloat("_Feed", _feed);
            _computeShader.SetFloat("_Kill", _kill);
            _computeShader.SetFloat("_DeltaTime", _deltaTime);

            Kernel kernel = new Kernel(_computeShader, "BuildGridBuffer");
            _computeShader.SetBuffer(kernel.Index, "_GridIndexBuffer", _gridIndexBuffer);
            _computeShader.SetBuffer(kernel.Index, "_VertexBuffer", _vertexBuffer);
            _computeShader.Dispatch(kernel.Index, _vertexNum / kernel.ThreadNumX + 1, 1, 1);

            BitonicSort.Normal(_computeShader, _gridIndexBuffer);

            kernel = new Kernel(_computeShader, "ClearGridIndexReferenceBuffer");
            _computeShader.SetBuffer(kernel.Index, "_GridIndexReferenceBuffer", _gridIndexReferenceBuffer);
            _computeShader.Dispatch(kernel.Index, _gridIndexReferenceBuffer.count / kernel.ThreadNumX + 1, 1, 1);

            kernel = new Kernel(_computeShader, "BuildGridIndexReferenceBuffer");
            _computeShader.SetBuffer(kernel.Index, "_GridIndexBuffer", _gridIndexBuffer);
            _computeShader.SetBuffer(kernel.Index, "_GridIndexReferenceBuffer", _gridIndexReferenceBuffer);
            _computeShader.Dispatch(kernel.Index, _gridIndexBuffer.count / kernel.ThreadNumX + 1, 1, 1);

            kernel = new Kernel(_computeShader, "CalcDensity");
            _computeShader.SetBuffer(kernel.Index, "_GridIndexBuffer", _gridIndexBuffer);
            _computeShader.SetBuffer(kernel.Index, "_GridIndexReferenceBuffer", _gridIndexReferenceBuffer);
            _computeShader.SetBuffer(kernel.Index, "_DensityBuffer", _densityBuffer);
            _computeShader.SetBuffer(kernel.Index, "_VertexBuffer", _vertexBuffer);
            _computeShader.Dispatch(kernel.Index, _gridIndexBuffer.count / kernel.ThreadNumX + 1, 1, 1);

            kernel = new Kernel(_computeShader, "Integrate");
            _computeShader.SetBuffer(kernel.Index, "_GridIndexBuffer", _gridIndexBuffer);
            _computeShader.SetBuffer(kernel.Index, "_GridIndexReferenceBuffer", _gridIndexReferenceBuffer);
            _computeShader.SetBuffer(kernel.Index, "_ReactionDiffusionParamsBuffer", _reactionDiffusionParamsBuffer);
            _computeShader.SetBuffer(kernel.Index, "_VertexBuffer", _vertexBuffer);
            _computeShader.SetBuffer(kernel.Index, "_DensityBuffer", _densityBuffer);
            _computeShader.Dispatch(kernel.Index, _vertexNum / kernel.ThreadNumX + 1, 1, 1);

            _renderer.Material.SetBuffer("_ReactionDiffusionParamsBuffer", _reactionDiffusionParamsBuffer);

            Graphics.DrawMesh(_mesh, transform.localToWorldMatrix, _renderer.Material, 0);
        }

        private void OnDestroy()
        {
            _vertexBuffer?.Dispose();
            _gridIndexBuffer?.Dispose();
            _gridIndexReferenceBuffer?.Dispose();
            _reactionDiffusionParamsBuffer?.Dispose();
            _densityBuffer?.Dispose();
            _renderer.Dispose();
        }
    }
}