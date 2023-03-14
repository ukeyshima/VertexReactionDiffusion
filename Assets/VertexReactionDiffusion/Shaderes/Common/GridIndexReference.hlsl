#ifndef INCLUDED_GRID_INDEX_REFERENCE
#define INCLUDED_GRID_INDEX_REFERENCE

#ifndef GRID_INDEX_REFERENCE_THREAD_NUM
#define GRID_INDEX_REFERENCE_THREAD_NUM 128
#endif

#include "Assets/VertexReactionDiffusion/Shaderes/Common/Grid.hlsl"
struct GridIndex { int index; int particleIndex; };
struct GridIndexReference { int startIndex; int endIndex; };

#define data_t GridIndex
#define COMPARISON(a,b) (a.index < b.index)
#include "Assets/VertexReactionDiffusion/Shaderes/Common/BitonicSort.hlsl"

#ifndef PARTICLE
struct Patcile { float3 position; };
#define PARTICLE Particle
#endif

#ifndef PARTICLE_BUFFER
RWStructuredBuffer<PARTICLE> _ParticleBuffer;
#define PARTICLE_BUFFER _ParticleBuffer
#endif

#ifndef SORTED_PARTICLE_BUFFER
RWStructuredBuffer<PARTICLE> _SortedParticleBuffer;
#define SORTED_PARTICLE_BUFFER _SortedParticleBuffer
#endif

#ifndef PARTICLE_NUM
int _ParticleNum;
#define PARTICLE_NUM _ParticleNum
#endif

RWStructuredBuffer<GridIndex> _GridIndexBuffer;
RWStructuredBuffer<GridIndexReference> _GridIndexReferenceBuffer;

int _GridIndexReferenceBufferLength;

#define SEARCH_NEIGHBOUR_PARTICLE_START(GRID_INDEXES,NEIGHBOUR_PARTICLE) \
for(int x = max(GRID_INDEXES.x - 1, 0); x <= min(GRID_INDEXES.x + 1, _GridNum.x - 1); x++){\
for(int y = max(GRID_INDEXES.y - 1, 0); y <= min(GRID_INDEXES.y + 1, _GridNum.y - 1); y++){\
for(int z = max(GRID_INDEXES.z - 1, 0); z <= min(GRID_INDEXES.z + 1, _GridNum.z - 1); z++){\
int neighborGridIndex = GridIndexesToGridIndex(int3(x, y, z));\
GridIndexReference gridIndexReference = _GridIndexReferenceBuffer[neighborGridIndex];\
for(int i = gridIndexReference.startIndex; i <= gridIndexReference.endIndex; i++){\
PARTICLE NEIGHBOUR_PARTICLE = SORTED_PARTICLE_BUFFER[i];\

#define SEARCH_NEIGHBOUR_PARTICLE_END }}}}

#define SEARCH_NEIGHBOUR_PARTICLE_WITH_INDEX_START(GRID_INDEXES,NEIGHBOUR_PARTICLE,NEIGHBOUR_PARTICLE_INDEX) \
SEARCH_NEIGHBOUR_PARTICLE_START(GRID_INDEXES,NEIGHBOUR_PARTICLE) \
int NEIGHBOUR_PARTICLE_INDEX = _GridIndexBuffer[i].particleIndex;

#define SEARCH_NEIGHBOUR_PARTICLE_WITH_INDEX_END SEARCH_NEIGHBOUR_PARTICLE_END

[numthreads(GRID_INDEX_REFERENCE_THREAD_NUM, 1, 1)]
void BuildGridBuffer(uint id : SV_DispatchThreadID)
{
    if(id > (uint)PARTICLE_NUM - 1) return;

    int gridIndex = PositionToGridIndex(PARTICLE_BUFFER[id].position);

    _GridIndexBuffer[id].index = gridIndex;
    _GridIndexBuffer[id].particleIndex = id;
}

[numthreads(GRID_INDEX_REFERENCE_THREAD_NUM, 1, 1)]
void ClearGridIndexReferenceBuffer(uint id : SV_DispatchThreadID)
{
    if(id > (uint)_GridIndexReferenceBufferLength - 1) return;

    _GridIndexReferenceBuffer[id].startIndex = 1;
    _GridIndexReferenceBuffer[id].endIndex = 0;
}

[numthreads(GRID_INDEX_REFERENCE_THREAD_NUM, 1, 1)]
void BuildGridIndexReferenceBuffer(uint id : SV_DispatchThreadID)
{
    if(id > (uint)PARTICLE_NUM - 1) return;

    int gridIndex = _GridIndexBuffer[id].index;
    int prevGridIndex = -1;
    int nextGridIndex = -1;

    if(id > 0) prevGridIndex = _GridIndexBuffer[id - 1].index;
    if(id < (uint)PARTICLE_NUM - 1) nextGridIndex = _GridIndexBuffer[id + 1].index;

    if(gridIndex != prevGridIndex) _GridIndexReferenceBuffer[gridIndex].startIndex = (int)id;
    if(gridIndex != nextGridIndex) _GridIndexReferenceBuffer[gridIndex].endIndex = (int)id;
}

[numthreads(GRID_INDEX_REFERENCE_THREAD_NUM, 1, 1)]
void BuildSortedParticleBuffer(uint id : SV_DispatchThreadID)
{
    if(id > (uint)PARTICLE_NUM - 1) return;

    int sortedParticleIndex = _GridIndexBuffer[id].particleIndex;
    SORTED_PARTICLE_BUFFER[id] = PARTICLE_BUFFER[sortedParticleIndex];
}

#endif