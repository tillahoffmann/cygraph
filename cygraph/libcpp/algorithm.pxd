cdef extern from "<algorithm>" namespace "std" nogil:
    SampleIt sample[PopulationIt, SampleIt, Distance, URBG](PopulationIt first, PopulationIt last, SampleIt out, Distance n, URBG&& g) except +
