from cython.operator cimport dereference
from libcpp.unordered_set cimport unordered_set as unordered_set_t
from libcpp.set cimport set as set_t
from libcpp.vector cimport vector as vector_t
from libcpp.algorithm cimport lower_bound


ctypedef int element_t


cdef class UniqueContainerExperiment:
    cdef vector_t[element_t] population

    def __init__(self, population):
        cdef element_t element
        for element in population:
            self.population.push_back(element)

    @property
    def methods(self):
        return ["insert_vector", "insert_set", "insert_unordered_set", "insert_vector_lower_bound"]

    def insert_vector(self, int repeat):
        """
        Insert elements into a vector without ensuring uniqueness.
        """
        cdef vector_t[element_t] container
        for _ in range(repeat):
            container.clear()
            for element in self.population:
                container.push_back(element)

    def insert_set(self, int repeat):
        """
        Insert elements into a standard set.
        """
        cdef set_t[element_t] container
        for _ in range(repeat):
            container.clear()
            for element in self.population:
                container.insert(element)

    def insert_unordered_set(self, int repeat):
        """
        Insert elements into an unordered set.
        """
        cdef unordered_set_t[element_t] container
        for _ in range(repeat):
            container.clear()
            for element in self.population:
                container.insert(element)

    def insert_vector_lower_bound(self, int repeat):
        """
        Insert elements into an ordered vector, ensuring uniqueness.
        """
        cdef vector_t[element_t] container
        for _ in range(repeat):
            container.clear()
            for element in self.population:
                it = lower_bound(container.begin(), container.end(), element)
                if it == container.end() or dereference(it) != element:
                    container.insert(it, element)


cdef class AllocationExperiment:
    @property
    def methods(self):
        return ["allocate_vector", "allocate_set", "allocate_unordered_set"]

    def allocate_vector(self, int repeats):
        cdef vector_t[element_t] container
        for _ in range(repeats):
            container = vector_t[element_t]()

    def allocate_set(self, int repeats):
        cdef set_t[element_t] container
        for _ in range(repeats):
            container = set_t[element_t]()

    def allocate_unordered_set(self, int repeats):
        cdef unordered_set_t[element_t] container
        for _ in range(repeats):
            container = unordered_set_t[element_t]()
