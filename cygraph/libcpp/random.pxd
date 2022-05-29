from libc.stdint cimport uint_fast32_t


cdef extern from "<random>" namespace "std" nogil:
    cdef cppclass mt19937:
        ctypedef uint_fast32_t result_type

        mt19937() except +
        mt19937(result_type seed) except +
        result_type operator()() except +
        result_type min() except +
        result_type max() except +
        void discard(size_t z) except +
        void seed(result_type seed) except +

    cdef cppclass random_device:
        ctypedef uint_fast32_t result_type
        random_device() except +
        result_type operator()() except +

    cdef cppclass poisson_distribution[T]:
        poisson_distribution() except +
        poisson_distribution(double) except +
        T operator()[Generator](Generator&) except +

    cdef cppclass binomial_distribution[T]:
        binomial_distribution() except +
        binomial_distribution(T, double) except +
        T operator()[Generator](Generator&) except +

    cpdef cppclass uniform_int_distribution[T]:
        uniform_int_distribution() except +
        uniform_int_distribution(T, T) except +
        T operator()[Generator](Generator&) except +

    cdef cppclass bernoulli_distribution:
        bernoulli_distribution() except +
        bernoulli_distribution(double) except +
        bint operator()[Generator](Generator&) except +
