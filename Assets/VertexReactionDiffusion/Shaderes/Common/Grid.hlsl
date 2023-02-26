#ifndef INCLUDED_GRID
#define INCLUDED_GRID

int3 _GridNum;
float3 _GridSize;
float3 _GridAreaMin;

int3 PositionToGridIndexes(float3 position)
{
    int3 gridIndexes = (position - _GridAreaMin) / _GridSize;
    return clamp(gridIndexes, 0, _GridNum - 1);
}

int GridIndexesToGridIndex(int3 gridIndexes)
{
    return gridIndexes.x + gridIndexes.y * _GridNum.x + gridIndexes.z * _GridNum.x * _GridNum.y;
}

int PositionToGridIndex(float3 position)
{
    int3 gridIndexes = PositionToGridIndexes(position);
    return GridIndexesToGridIndex(gridIndexes);
}

#endif //INCLUDED_GRID
