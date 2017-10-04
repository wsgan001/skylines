#ifndef SLYLINES_QUERIES_INPUT_DATA_HPP
#define SLYLINES_QUERIES_INPUT_DATA_HPP

#include <mutex>

#include "export_import.hpp"
#include "common/irenderable.hpp"
#include "queries/data/data_structures.hpp"

namespace sl { namespace queries {

    class DataCapable;

    template<class T>
    class skylines_engine_DLL_EXPORTS Data {
        friend class DataCapable;
    public:
        Data() {}

        Data(std::vector<T> &&points) {
            points_ = std::move(points);
        }

        Data& operator=(Data &&points) {
            points_ = std::move(points.points_);
            return *this;
        }

        void InitRandom(size_t num_points) {
            data::UniformRealRandomGenerator r;
            points_.clear();
            points_.reserve(num_points);
            for (size_t i = 0; i < num_points; i++) {
                points_.emplace_back(T(r));
            }
        }

        const std::vector<T> & GetPoints() const { return points_; }
        void Clear() { points_.clear(); }
        void Add(T &&v) { points_.emplace_back(std::move(v)); }
        void Add(const T &v) { points_.push_back(v); }
        void SafetyAdd(const T &v) {
            std::lock_guard<std::mutex> lock(output_mutex_);
            points_.push_back(v);
        }

        T* GetDataPointer() { return &points_[0]; }

        void Resize(size_t new_size) { points_.resize(new_size); }
    protected:
        std::mutex output_mutex_;
        std::vector<T> points_;
    };

    template<class T>
    class skylines_engine_DLL_EXPORTS NonConstData : public Data<T> {
    public:
        NonConstData & operator=(const NonConstData &other) {
            points_ = other.points_;
            return *this;
        }
        NonConstData() {}

        NonConstData(NonConstData<T> &&other) {
            points_ = other.points_;
        }

        std::vector<T> & Points() { return points_; }

        NonConstData& operator=(const Data &other) {
            points_.clear();
            points_.assign(other.GetPoints().cbegin(), other.GetPoints().cend());
            return *this;
        }
    };
}}
#endif // !SLYLINES_QUERIES_INPUT_DATA_HPP
