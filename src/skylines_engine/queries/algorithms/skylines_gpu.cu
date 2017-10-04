#include <vector>
#include <iostream>

#include <cuda_runtime.h>

#include "gpu/gpu_memory.hpp"
#include "queries/data/data_structures.hpp"
#include "queries/algorithms/algorithm.cuh"
#include "queries/algorithms/distance_type.hpp"

#define SHARED_MEM_ELEMENTS 1024

/*
Total amount of constant memory:    65536 bytes
sizeof(sl::queries::data::Point):   8 bytes
Max elements:                       65536 / 8 = 8192
*/
#define MAX_CONST_MEM_ELEMENTS 8192

__constant__ sl::queries::data::Point device_input_q[MAX_CONST_MEM_ELEMENTS];

__device__ inline bool NeartestFunc(const float a, const float b) {
    return a <= b;
}

__device__ inline bool FurthestFunc(const float a, const float b) {
    return a >= b;
}

template<class Comparator>
__device__ void _ComputePartialSkyline(
    const sl::queries::data::WeightedPoint *input_p,
    size_t input_p_size,
    int input_q_size,
    Comparator comparator_function,
    unsigned int *result) {

    __shared__ sl::queries::data::WeightedPoint shared_input_p[SHARED_MEM_ELEMENTS];

    int block_offset = blockIdx.x * blockDim.x; // we just have one dimension grids
    size_t global_pos = block_offset + threadIdx.x;

    sl::queries::data::WeightedPoint skyline_candidate(input_p[global_pos]);
    bool is_skyline = global_pos < input_p_size;

    for (size_t current_input_p_pos = 0; current_input_p_pos < input_p_size; current_input_p_pos += SHARED_MEM_ELEMENTS) {
        //all threads in the block loads to shared
        shared_input_p[threadIdx.x] = input_p[threadIdx.x + current_input_p_pos];
        __syncthreads();

        if (is_skyline) {
            #pragma unroll SHARED_MEM_ELEMENTS
            for (int i = 0; i < SHARED_MEM_ELEMENTS; i++) {
                if (current_input_p_pos + i != global_pos &&current_input_p_pos + i < input_p_size) { // do not check against the same point
                    if (IsDominated_impl(skyline_candidate, shared_input_p[i], device_input_q, input_q_size, comparator_function)) {
                        is_skyline = false;
                        break;
                    }
                }
            }
        }
        __syncthreads();
    }

    result[global_pos] = is_skyline ? 1 : 0;
}

__global__ void ComputePartialSkyline(
    const sl::queries::data::WeightedPoint *input_p, 
    size_t input_p_size,
    int input_q_size,
    sl::queries::algorithms::DistanceType distance_type,
    unsigned int *result) {

    switch (distance_type) {
        case sl::queries::algorithms::DistanceType::Neartest:
            _ComputePartialSkyline(input_p, input_p_size, input_q_size, NeartestFunc, result);
            break;
        case sl::queries::algorithms::DistanceType::Furthest:
            _ComputePartialSkyline(input_p, input_p_size, input_q_size, FurthestFunc, result);
            break;
        default:
            break;
    }
}

template<typename T>
T inline divUp(T a, T b) {
    return (a + b - 1) / b;
}

template<typename T>
T roundUp(T numToRound, T multiple)
{
    if (multiple == 0)
        return numToRound;

    T remainder = numToRound % multiple;
    if (remainder == 0)
        return numToRound;

    return numToRound + multiple - remainder;
}

extern "C" bool CheckInputCorrectness(const std::vector<sl::queries::data::WeightedPoint> &input_p,
    const std::vector<sl::queries::data::Point> &input_q) {
    if (input_q.size() > MAX_CONST_MEM_ELEMENTS) return false;
    return true;
}

extern "C" void ComputeGPUSkyline(
    const std::vector<sl::queries::data::WeightedPoint> &input_p,
    const std::vector<sl::queries::data::Point> &input_q,
    std::vector<sl::queries::data::WeightedPoint> *output,
    sl::queries::algorithms::DistanceType distance_type) {

    sl::gpu::GPUStream gpu_stream;

    //copy to const memory the input Q
    cudaMemcpyToSymbolAsync(device_input_q, input_q.data(), sizeof(sl::queries::data::Point) * input_q.size(), 0, cudaMemcpyKind::cudaMemcpyHostToDevice, gpu_stream());

    size_t input_p_size = input_p.size();
    int input_q_size = static_cast<int>(input_q.size());

    size_t input_p_size_SHARED_MEM_SIZE_multiple = roundUp<size_t>(input_p.size(), SHARED_MEM_ELEMENTS);

    //copy to global memory the input P
    sl::gpu::GPUMemory<sl::queries::data::WeightedPoint> input_p_d(input_p_size_SHARED_MEM_SIZE_multiple);
    input_p_d.UploadToDeviceAsync(input_p, gpu_stream); //the final values maybe empty

    sl::gpu::GPUMemory<unsigned int> result_d(input_p_size_SHARED_MEM_SIZE_multiple);
    /*
    MAX number of threads per MS is 2048.
    MAX number of threads per block 1024 => max blockDim.y = 1
    */
    dim3 threadsPerBlock(SHARED_MEM_ELEMENTS, 1);
    int total_numBlocks = static_cast<int>(divUp(input_p_size, static_cast<size_t>(threadsPerBlock.x * threadsPerBlock.y)));
    dim3 grid(total_numBlocks, 1);

    ComputePartialSkyline <<< grid, threadsPerBlock, 0, gpu_stream() >>> (input_p_d(), input_p_size, input_q_size, distance_type, result_d());

    std::vector<unsigned int> result(input_p_size);
    result_d.DownloadToHostAsync(result.data(), input_p_size, gpu_stream);
    gpu_stream.Syncronize();

    for (size_t i = 0; i < result.size(); i++) {
        if (result[i] == 1) {
            output->push_back(input_p[i]);
        }
    }
}


