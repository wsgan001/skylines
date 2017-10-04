#ifndef SKYLINES_QUERIES_ALGORITHMS_SINGLE_THREAD_BRUTE_FORCE_DISCARTING_HPP
#define SKYLINES_QUERIES_ALGORITHMS_SINGLE_THREAD_BRUTE_FORCE_DISCARTING_HPP

#include "queries/algorithms/algorithm.hpp"

namespace sl { namespace queries { namespace algorithms {
    class SingleThreadBruteForceDiscarting : public Algorithm {
    public:
        SingleThreadBruteForceDiscarting(
            const Data<data::WeightedPoint> &input_p, const Data<data::Point> &input_q) :
            Algorithm("SingleThreadBruteForceDiscarting", input_p, input_q) {
        }

    protected:
        void Run(NonConstData<data::WeightedPoint> *output, DistanceType distance_type) final;
        void Compute(NonConstData<data::WeightedPoint> *output, DistanceType distance_type);

        template<class Comparator>
        void _Compute(Comparator comparator_funciton, NonConstData<data::WeightedPoint> *output);
    };
}}}

#endif