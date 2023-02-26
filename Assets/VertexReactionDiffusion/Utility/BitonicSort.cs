//Original Code : https://github.com/toropippi/BitonicSort_ComputeShader

using UnityEngine;

namespace VertexReactionDiffusion.Utility
{
    public static class BitonicSort
    {
        public static void Fastest(ComputeShader computeShader, GraphicsBuffer gpu_data)
        {
            Kernel kernel_ParallelBitonic_B16 = new Kernel(computeShader, "ParallelBitonic_B16");
            Kernel kernel_ParallelBitonic_B8 = new Kernel(computeShader, "ParallelBitonic_B8");
            Kernel kernel_ParallelBitonic_B4 = new Kernel(computeShader, "ParallelBitonic_B4");
            Kernel kernel_ParallelBitonic_B2 = new Kernel(computeShader, "ParallelBitonic_B2");
            Kernel kernel_ParallelBitonic_C4 = new Kernel(computeShader, "ParallelBitonic_C4");
            Kernel kernel_ParallelBitonic_C2 = new Kernel(computeShader, "ParallelBitonic_C2");

            int n = gpu_data.count;
            computeShader.SetBuffer(kernel_ParallelBitonic_B16.Index, "data", gpu_data);
            computeShader.SetBuffer(kernel_ParallelBitonic_B8.Index, "data", gpu_data);
            computeShader.SetBuffer(kernel_ParallelBitonic_B4.Index, "data", gpu_data);
            computeShader.SetBuffer(kernel_ParallelBitonic_B2.Index, "data", gpu_data);
            computeShader.SetBuffer(kernel_ParallelBitonic_C4.Index, "data", gpu_data);
            computeShader.SetBuffer(kernel_ParallelBitonic_C2.Index, "data", gpu_data);

            int nlog = (int)(Mathf.Log(n, 2));
            int B_indx, inc;
            Kernel kernel;

            for (int i = 0; i < nlog; i++)
            {
                inc = 1 << i;
                for (int j = 0; j < i + 1; j++)
                {
                    if (inc <= 128) break;

                    if (inc >= 2048)
                    {
                        B_indx = 16;
                        kernel = kernel_ParallelBitonic_B16;
                    }
                    else if (inc >= 1024)
                    {
                        B_indx = 8;
                        kernel = kernel_ParallelBitonic_B8;
                    }
                    else if (inc >= 512)
                    {
                        B_indx = 4;
                        kernel = kernel_ParallelBitonic_B4;
                    }
                    else
                    {
                        B_indx = 2;
                        kernel = kernel_ParallelBitonic_B2;
                    }


                    computeShader.SetInt("inc", inc * 2 / B_indx);
                    computeShader.SetInt("dir", 2 << i);
                    computeShader.Dispatch(kernel.Index, n / B_indx / kernel.ThreadNumX, 1, 1);
                    inc /= B_indx;
                }

                computeShader.SetInt("inc0", inc);
                computeShader.SetInt("dir", 2 << i);
                if ((inc == 8) | (inc == 32) | (inc == 128))
                {
                    computeShader.Dispatch(kernel_ParallelBitonic_C4.Index, n / 4 / 64, 1, 1);
                }
                else
                {
                    computeShader.Dispatch(kernel_ParallelBitonic_C2.Index, n / 2 / 128, 1, 1);
                }
            }
        }

    public static void NoUseSharedMemory(ComputeShader computeShader, GraphicsBuffer gpu_data)
    {
        Kernel kernel_ParallelBitonic_B16 = new Kernel(computeShader, "ParallelBitonic_B16");
        Kernel kernel_ParallelBitonic_B8 = new Kernel(computeShader, "ParallelBitonic_B8");
        Kernel kernel_ParallelBitonic_B4 = new Kernel(computeShader, "ParallelBitonic_B4");
        Kernel kernel_ParallelBitonic_B2 = new Kernel(computeShader, "ParallelBitonic_B2");

        int n = gpu_data.count;
        computeShader.SetBuffer(kernel_ParallelBitonic_B16.Index, "data", gpu_data);
        computeShader.SetBuffer(kernel_ParallelBitonic_B8.Index, "data", gpu_data);
        computeShader.SetBuffer(kernel_ParallelBitonic_B4.Index, "data", gpu_data);
        computeShader.SetBuffer(kernel_ParallelBitonic_B2.Index, "data", gpu_data);

        int nlog = (int)(Mathf.Log(n, 2));
        int B_indx, inc;
        Kernel kernel;

        for (int i = 0; i < nlog; i++)
        {
            inc = 1 << i;
            for (int j = 0; j < i + 1; j++)
            {
                if (inc == 0) break;

                if ((inc >= 8) & (nlog >= 10))
                {
                    B_indx = 16;
                    kernel = kernel_ParallelBitonic_B16;
                }
                else if ((inc >= 4) & (nlog >= 9))
                {
                    B_indx = 8;
                    kernel = kernel_ParallelBitonic_B8;
                }
                else if ((inc >= 2) & (nlog >= 8))
                {
                    B_indx = 4;
                    kernel = kernel_ParallelBitonic_B4;
                }
                else
                {
                    B_indx = 2;
                    kernel = kernel_ParallelBitonic_B2;
                }

                computeShader.SetInt("inc", inc * 2 / B_indx);
                computeShader.SetInt("dir", 2 << i);
                computeShader.Dispatch(kernel.Index, n / B_indx / kernel.ThreadNumX, 1, 1);
                inc /= B_indx;
            }
        }
    }

        public static void Normal(ComputeShader computeShader, GraphicsBuffer gpu_data)
        {
            Kernel kernel_ParallelBitonic_B2 = new Kernel(computeShader, "ParallelBitonic_B2");

            int n = gpu_data.count;
            computeShader.SetBuffer(kernel_ParallelBitonic_B2.Index, "data", gpu_data);

            int nlog = (int)(Mathf.Log(n, 2));
            int B_indx, inc;

            for (int i = 0; i < nlog; i++)
            {
                inc = 1 << i;
                for (int j = 0; j < i + 1; j++)
                {
                    B_indx = 2;
                    computeShader.SetInt("inc", inc * 2 / B_indx);
                    computeShader.SetInt("dir", 2 << i);
                    computeShader.Dispatch(kernel_ParallelBitonic_B2.Index, n / B_indx / kernel_ParallelBitonic_B2.ThreadNumX, 1, 1);
                    inc /= B_indx;
                }
            }
        }
    }
}