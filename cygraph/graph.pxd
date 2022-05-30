from libcpp.unordered_map cimport unordered_map as unordered_map_t
from libcpp.unordered_set cimport unordered_set as unordered_set_t
from libcpp.utility cimport pair as pair_t
from libcpp.vector cimport vector as vector_t


ctypedef long count_t
ctypedef long node_t
ctypedef unordered_set_t[node_t] node_set_t
ctypedef vector_t[node_t] node_list_t
ctypedef unordered_map_t[node_t, node_set_t] adjacency_map_t
ctypedef unordered_map_t[node_t, count_t] degree_map_t
ctypedef pair_t[node_t, node_t] edge_t
ctypedef vector_t[edge_t] edge_list_t


cdef class Graph:
    cdef str _name
    cdef dict _property_cache
    cdef adjacency_map_t _adjacency_map

    cpdef int is_directed(self)
    cpdef int is_multigraph(self)

    cpdef int add_node(self, node_t node)
    cpdef int add_nodes_from(self, node_set_t nodes)
    cpdef int _remove_node(self, node_t node)
    cpdef int remove_node(self, node_t node) except -1
    cpdef int remove_nodes_from(self, node_set_t nodes)
    cpdef int has_node(self, node_t node)
    cpdef int number_of_nodes(self)

    cpdef int add_edge(self, node_t u, node_t v)
    cpdef int add_edges_from(self, edge_list_t edges)
    cpdef int _remove_edge(self, node_t u, node_t v)
    cpdef int remove_edge(self, node_t u, node_t v) except -1
    cpdef int remove_edges_from(self, edge_list_t edges)
    cpdef int has_edge(self, node_t u, node_t v)
    cpdef int number_of_edges(self)
    cdef int _add_directed_edge(self, node_t source, node_t target)
    cdef int _remove_directed_edge(self, node_t source, node_t target)
