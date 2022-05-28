from cython.operator cimport dereference


cdef class Graph:
    def __init__(self):
        self._property_cache = {}

    @property
    def name(self):
        return self._name

    @name.setter
    def name(self, value):
        self._name = value

    def _get_view(self, name: str, cls: type):
        view = self._property_cache.get(name)
        if view is not None:
            return view
        view = self._property_cache[name] = cls(self)
        return view

    @property
    def nodes(self):
        return self._get_view("nodes", NodeView)

    @property
    def edges(self):
        return self._get_view("edges", EdgeView)

    @property
    def degree(self):
        return self._get_view("degree", DegreeView)

    @property
    def neighbors(self):
        return self._get_view("neighbors", NeighborView)

    @property
    def adj(self):
        return self._adjacency_map

    def size(self):
        return self.number_of_edges()

    def __len__(self):
        return self.number_of_nodes()

    def __iter__(self):
        # `iter` implicitly converts to a python set, ensuring that nodes are ordered.
        return iter(self._nodes)

    def __getitem__(self, node):
        return self.neighbors(node)

    cpdef int add_node(self, node_t node):
        return self._nodes.insert(node).second

    cpdef int add_nodes_from(self, node_set_t nodes):
        cdef count_t num_added = 0
        cdef node_t node
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
        cdef node_t node
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
    """
    Base class for graph views to expose state to python.
    """
    cdef Graph graph

    def __init__(self, graph: Graph):
        self.graph = graph


cdef class NodeView(View):
    """
    View yielding sorted nodes.
    """
    def __call__(self):
        return self

    def __iter__(self):
        # `iter` implicitly converts to a python set, ensuring that nodes are ordered.
        return iter(self.graph)


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


cdef class NeighborView(View):
    def __call__(self, node: node_t):
        return self.graph._adjacency_map[node]
