//Original Code : https://github.com/toropippi/BitonicSort_ComputeShader

#ifndef INCLUDED_BITONIC_SORT
#define INCLUDED_BITONIC_SORT

#define BITONIC_SORT_THREAD_NUM 64
//構造体と比較を自前で定義する必要あり。
//構造体が128byteを超すと共有メモリが使えなくなる
#ifndef data_t
struct Mystruct { float key; uint index; };
#define data_t Mystruct
#endif //data_t
#ifndef COMPARISON
#define COMPARISON(a,b) ( a.key > b.key )
#endif //COMPARISON(a,b)
//ここまで


#define ORDER(a,b) { bool swap = reverse ^ COMPARISON(a,b); \
  data_t auxa = a; data_t auxb = b; if (swap) { a = auxb; b = auxa; } }

#define ORDERV(x,a,b) { bool swap = reverse ^ COMPARISON(x[a],x[b]); \
      data_t auxa = x[a]; data_t auxb = x[b]; \
      if (swap) { x[a] = auxb; x[b] = auxa; } }
#define B2V(x,a) { ORDERV(x,a,a+1) }
#define B4V(x,a) { for (int i4=0;i4<2;i4++) { ORDERV(x,a+i4,a+i4+2) } B2V(x,a) B2V(x,a+2) }
#define B8V(x,a) { for (int i8=0;i8<4;i8++) { ORDERV(x,a+i8,a+i8+4) } B4V(x,a) B4V(x,a+4) }
#define B16V(x,a) { for (int i16=0;i16<8;i16++) { ORDERV(x,a+i16,a+i16+8) } B8V(x,a) B8V(x,a+8) }


RWStructuredBuffer<data_t> data;
groupshared data_t aux[256];
int inc;
int inc0;
int dir;

[numthreads(BITONIC_SORT_THREAD_NUM, 1, 1)]
//void ParallelBitonic_B16(__global data_t* data, int inc, int dir)
void ParallelBitonic_B16(uint threadid : SV_DispatchThreadID)
{
	int t = threadid; // thread index
	int low = t & (inc - 1); // low order bits (below INC)
	int i = ((t - low) << 4) + low; // insert 0000 at position INC
	bool reverse = ((dir & i) == 0); // asc/desc order

	// Load
	data_t x[16];
	{for (int k = 0; k < 16; k++) x[k] = data[k * inc + i];}

	// Sort
	B16V(x, 0)

	// Store
    {for (int k = 0; k < 16; k++) data[k * inc + i] = x[k];}
}

[numthreads(BITONIC_SORT_THREAD_NUM, 1, 1)]
//void ParallelBitonic_B8(__global data_t* data, int inc, int dir)
void ParallelBitonic_B8(uint threadid : SV_DispatchThreadID)
{
	int t = threadid; // thread index
	int low = t & (inc - 1); // low order bits (below INC)
	int i = ((t - low) << 3) + low; // insert 000 at position INC
	bool reverse = ((dir & i) == 0); // asc/desc order

	// Load
	data_t x[8];
	{for (int k = 0; k < 8; k++) x[k] = data[k * inc + i];}

	// Sort
	B8V(x, 0)

	// Store
	{for (int k = 0; k < 8; k++) data[k * inc + i] = x[k];}
}

[numthreads(BITONIC_SORT_THREAD_NUM, 1, 1)]
//void ParallelBitonic_B4(__global data_t* data, int inc, int dir)
void ParallelBitonic_B4(uint threadid : SV_DispatchThreadID)
{
	int t = threadid; // thread index
	int low = t & (inc - 1); // low order bits (below INC)
	int i = ((t - low) << 2) + low; // insert 00 at position INC
	bool reverse = ((dir & i) == 0); // asc/desc order

	// Load
	data_t x0 = data[i];
	data_t x1 = data[inc + i];
	data_t x2 = data[2 * inc + i];
	data_t x3 = data[3 * inc + i];

	// Sort
	ORDER(x0, x2)
	ORDER(x1, x3)
	ORDER(x0, x1)
	ORDER(x2, x3)

	// Store
	data[i] = x0;
	data[inc + i] = x1;
	data[2 * inc + i] = x2;
	data[3 * inc + i] = x3;
}

[numthreads(BITONIC_SORT_THREAD_NUM, 1, 1)]
//void ParallelBitonic_B2(__global data_t* data, int inc, int dir)
void ParallelBitonic_B2(uint threadid : SV_DispatchThreadID)
{
	int t = threadid; // thread index
	int low = t & (inc - 1); // low order bits (below INC)
	int i = (t << 1) - low; // insert 0 at position INC
	bool reverse = ((dir & i) == 0); // asc/desc order

	// Load
	data_t x0 = data[i];
	data_t x1 = data[inc + i];

	// Sort
	ORDER(x0, x1)

	// Store
	data[i] = x0;
	data[inc + i] = x1;
}



#define LOCALSIZE_C2 128
[numthreads(LOCALSIZE_C2, 1, 1)]
//void ParallelBitonic_C2(__global data_t* data, int inc0, int dir)
void ParallelBitonic_C2(uint threadid : SV_DispatchThreadID)
{
	int t = threadid; // thread index
	int wgBits = 2 * LOCALSIZE_C2 - 1; // bit mask to get index in local memory AUX (size is 2*WG)

	for (int inc = inc0; inc > 0; inc >>= 1)
	{
		int low = t & (inc - 1); // low order bits (below INC)
		int i = (t << 1) - low; // insert 0 at position INC
		bool reverse = ((dir & i) == 0); // asc/desc order
		data_t x0, x1;

		// Load
		if (inc == inc0)
		{
			// First iteration: load from global memory
			x0 = data[i];
			x1 = data[i + inc];
		}
		else
		{
			// Other iterations: load from local memory
			GroupMemoryBarrierWithGroupSync();
			x0 = aux[i & wgBits];
			x1 = aux[(i + inc) & wgBits];
		}

		// Sort
		ORDER(x0, x1)

			// Store
			if (inc == 1)
			{
				// Last iteration: store to global memory
				data[i] = x0;
				data[i + inc] = x1;
			}
			else
			{
				// Other iterations: store to local memory
				GroupMemoryBarrierWithGroupSync();
				aux[i & wgBits] = x0;
				aux[(i + inc) & wgBits] = x1;
			}
	}
}


#define LOCALSIZE_C4 64
[numthreads(LOCALSIZE_C4, 1, 1)]
//void ParallelBitonic_C4(__global data_t* data, int inc0, int dir)
void ParallelBitonic_C4(uint threadid : SV_DispatchThreadID)
{
	int t = threadid; // thread index
	int wgBits = 4 * LOCALSIZE_C4 - 1; // bit mask to get index in local memory AUX (size is 4*WG)
	int inc, low, i;
	bool reverse;
	data_t x[4];

	// First iteration, global input, local output
	inc = inc0 >> 1;
	low = t & (inc - 1); // low order bits (below INC)
	i = ((t - low) << 2) + low; // insert 00 at position INC
	reverse = ((dir & i) == 0); // asc/desc order
	{for (int k = 0; k < 4; k++) x[k] = data[i + k * inc];}
	B4V(x, 0);
	{for (int k = 0; k < 4; k++) aux[(i + k * inc) & wgBits] = x[k];}
	GroupMemoryBarrierWithGroupSync();

	// Internal iterations, local input and output
	for (; inc > 1; inc >>= 2)
	{
		low = t & (inc - 1); // low order bits (below INC)
		i = ((t - low) << 2) + low; // insert 00 at position INC
		reverse = ((dir & i) == 0); // asc/desc order
		{for (int k = 0; k < 4; k++) x[k] = aux[(i + k * inc) & wgBits];}
		B4V(x, 0);
		GroupMemoryBarrierWithGroupSync();
		{for (int k = 0; k < 4; k++) aux[(i + k * inc) & wgBits] = x[k];}
		GroupMemoryBarrierWithGroupSync();
	}

	// Final iteration, local input, global output, INC=1
	i = t << 2;
	reverse = ((dir & i) == 0); // asc/desc order
	{for (int k = 0; k < 4; k++) x[k] = aux[(i + k) & wgBits];}
	B4V(x, 0);
	{for (int k = 0; k < 4; k++) data[i + k] = x[k];}
}

#endif //INCLUDED_BITONIC_SORT