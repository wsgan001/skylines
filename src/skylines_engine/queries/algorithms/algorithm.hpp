#ifndef SKYLINES_QUERIES_ALGORITHMS_ALGORITHM_HPP
#define SKYLINES_QUERIES_ALGORITHMS_ALGORITHM_HPP

#include <algorithm>
#include <stack>
#include <ppl.h>
#include <future>
#include <functional>

#include "queries/data.hpp"
#include "common/skyline_element.hpp"
#include "queries/algorithms/algorithm.cuh"

namespace sl { namespace queries { namespace algorithms {
    class Algorithm : public common::SkylineElement {
    public:
        Algorithm(
            const std::string &logger,
            const Data<data::WeightedPoint> &input_p, const Data<data::Point> &input_q);

        virtual void Run(NonConstData<data::WeightedPoint> *output) = 0;


        inline bool static IsDominated(const data::WeightedPoint &a, const data::WeightedPoint &b, const std::vector<data::Point> &q) {
            return IsDominated_impl(a, b, q.data(), static_cast<int>(q.size()));
        }

        inline int Dominator(const data::WeightedPoint &a, const data::WeightedPoint &b, const std::vector<data::Point> &q) {
            bool a_is_dominated_by_b = true;
            bool b_is_dominated_by_a = true;
            for (const data::Point p_q : q) {
                float a_distance = a.Distance(p_q);
                float b_distance = b.Distance(p_q);
                if (a_distance <= b_distance) {
                    a_is_dominated_by_b = false;
                    if (!b_is_dominated_by_a) return -1;
                }
                if (b_distance <= a_distance) {
                    b_is_dominated_by_a = false;
                    if (!a_is_dominated_by_b) return -1;
                }
            }
            //at this point one domains the other
            if (a_is_dominated_by_b) return 1;
            return 0;
        }

    protected:
        virtual bool Init(NonConstData<data::WeightedPoint> *output);
        bool IsEmpty();
        void ClearOutput(NonConstData<data::WeightedPoint> *output);

        const Data<data::WeightedPoint> &input_p_;
        const Data<data::Point> &input_q_;
    };
}}}

#endif
