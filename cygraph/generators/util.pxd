from ..libcpp.random cimport mt19937

cdef class RandomEngine:
    cdef mt19937 instance


cpdef RandomEngine get_random_engine(arg=*)
