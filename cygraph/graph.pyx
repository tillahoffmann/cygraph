from cython.operator cimport dereference


cdef class Graph:
    @property
    def name(self):
        return self._name

    @name.setter
    def name(self, value):
        self._name = value

    @property
    def nodes(self):
        return NodeView(self)

    @property
    def edges(self):
        return EdgeView(self)

    @property
    def degree(self):
        return DegreeView(self)

    @property
    def adj(self):
        return self._adjacency_map

    def size(self):
        return self.number_of_edges()

    def __len__(self):
        return self.number_of_nodes()

    def __iter__(self):
        for node in sorted(self._nodes):
            yield node

    def __getitem__(self, node):
        return self.neighbors(node)

    def neighbors(self, node):
        return sorted(self._adjacency_map[node])

    cpdef int add_node(self, node_t node):
        return self._nodes.insert(node).second

    cpdef int add_nodes_from(self, node_set_t nodes):
        cdef count_t num_added = 0
        for node in nodes:
            num_added += self.add_node(node)
        return num_added

    cpdef int remove_node(self, node_t node):
        for neighbor in self._adjacency_map[node]:
            self._remove_directed_edge(neighbor, node)
        self._adjacency_map.erase(node)
        return self._nodes.erase(node)

    cpdef int remove_nodes_from(self, node_set_t nodes):
        cdef count_t num_removed = 0
        for node in nodes:
            num_removed += self.remove_node(node)
        return num_removed

    cpdef int has_node(self, node_t node):
        return self._nodes.find(node) != self._nodes.end()

    cpdef int number_of_nodes(self):
        return self._nodes.size()

    cpdef int is_directed(self):
        return False

    cpdef int is_multigraph(self):
        return False

    cdef int _add_directed_edge(self, node_t source, node_t target):
        return self._adjacency_map[source].insert(target).second

    cdef int _remove_directed_edge(self, node_t source, node_t target):
        return self._adjacency_map[source].erase(target)

    cpdef int add_edge(self, node_t u, node_t v):
        self.add_node(u)
        self.add_node(v)
        return self._add_directed_edge(u, v) and self._add_directed_edge(v, u)

    cpdef int add_edges_from(self, edge_set_t edges):
        cdef count_t num_added = 0
        for edge in edges:
            num_added += self.add_edge(edge.first, edge.second)
        return num_added

    cpdef int remove_edge(self, node_t u, node_t v):
        return self._remove_directed_edge(u, v) and self._remove_directed_edge(v, u)

    cpdef int remove_edges_from(self, edge_set_t edges):
        cdef count_t num_removed = 0
        for edge in edges:
            num_removed += self.remove_edge(edge.first, edge.second)

    cpdef int has_edge(self, node_t u, node_t v):
        it = self._adjacency_map.find(u)
        if it == self._adjacency_map.end():
            return False
        return dereference(it).second.find(v) != dereference(it).second.end()

    cpdef int number_of_edges(self):
        cdef int num_edges = 0
        for item in self._adjacency_map:
            num_edges += item.second.size()
        return num_edges // 2


cdef class View:
    cdef Graph graph

    def __init__(self, graph):
        self.graph = graph


cdef class NodeView(View):
    """
    View yielding sorted nodes.
    """
    def __call__(self):
        return self

    def __iter__(self):
        for node in sorted(self.graph._nodes):
            yield node


cdef class EdgeView(View):
    """
    Edge view yielding tuples of nodes.
    """
    def __call__(self):
        return self

    def __iter__(self):
        for node in sorted(self.graph._adjacency_map):
            for neighbor in sorted(self.graph._adjacency_map[node]):
                if node <= neighbor:
                    yield (node, neighbor)


cdef class DegreeView(View):
    """
    Degree view yielding sorted tuples `(node, degree)`. It supports indexing.
    """
    def __getitem__(self, node):
        return self.graph._adjacency_map[node].size()

    def __iter__(self):
        for node in sorted(self.graph._adjacency_map):
            yield node, self.graph._adjacency_map[node].size()

    def __call__(self, node=None):
        if node is None:
            return self
        else:
            return self[node]
