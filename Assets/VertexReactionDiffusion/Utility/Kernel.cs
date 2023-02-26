using UnityEngine;

namespace VertexReactionDiffusion.Utility
{
    public class Kernel
    {
        private int _index;
        private uint _threadNumX;
        private uint _threadNumY;
        private uint _threadNumZ;

        public int Index { get => _index; }
        public int ThreadNumX { get => (int)_threadNumX; }
        public int ThreadNumY { get => (int)_threadNumY; }
        public int ThreadNumZ { get => (int)_threadNumZ; }

        public Kernel(ComputeShader cs, string kernel)
        {
            _index = cs.FindKernel(kernel);
            cs.GetKernelThreadGroupSizes(_index, out _threadNumX, out _threadNumY, out _threadNumZ);
        }
    }
}