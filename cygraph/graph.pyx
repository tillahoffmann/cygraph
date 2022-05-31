from cython.operator cimport dereference, preincrement
import numbers
import typing


IF DEBUG_LOGGING:
    import logging
    LOGGER = logging.getLogger()


cdef class Graph:
    """
    Undirected, unweighted, unattributed graph that is compatible with :class:`networkx.Graph` by
    duck-typing. Detailed descriptions of all methods can be found in the networkx documentation.
    """
    def __init__(self):
        self._property_cache = {}

    @property
    def name(self):
        """
        str: Name of the graph (mostly for compatibility with networkx).
        """
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
        """
        NodeView: View of nodes, supporting relatively fast iteration.
        """
        return self._get_view("nodes", NodeView)

    @property
    def edges(self) -> EdgeView:
        """
        EdgeView: View of connectivity as an edge list.
        """
        return self._get_view("edges", EdgeView)

    @property
    def degree(self):
        """
        DegreeView: View of node degrees, supporting indexing by node label.
        """
        return self._get_view("degree", DegreeView)

    @property
    def neighbors(self) -> NeighborView:
        """
        NeighborView: View of node neighbors, supporting indexing by node label.
        """
        return self._get_view("neighbors", NeighborView)

    @property
    def adj(self):
        """
        typing.Dict[int, typing.Set[int]]: Adjacency map, mapping nodes to sets of neighbors.
        """
        return self._adjacency_map

    def size(self) -> int:
        """
        Returns the number of edges. :meth:`number_of_edges` is preferred.
        """
        return self.number_of_edges()

    def __len__(self):
        return self.number_of_nodes()

    def __iter__(self):
        return _NodeIterator(self)

    def __getitem__(self, node) -> typing.Set[int]:
        return self.neighbors(node)

    cpdef int add_node(self, node_t node):
        """
        Add a single node.

        Args:
            node: Node to add.
        """
        # Using [node] implicitly creates the node, but we don't know whether it existed before.
        self._adjacency_map[node]
        IF DEBUG_LOGGING:
            LOGGER.info("added node %d", node)

    cpdef int add_nodes_from(self, node_set_t nodes):
        """
        Add multiple nodes.

        Args:
            nodes: Container of nodes to add.
        """
        cdef node_t node
        for node in nodes:
            self.add_node(node)

    cpdef int _remove_node(self, node_t node):
        it = self._adjacency_map.find(node)
        if it == self._adjacency_map.end():
            return False
        for neighbor in dereference(it).second:
            self._remove_directed_edge(neighbor, node)
        self._adjacency_map.erase(it)
        return True

    cpdef int remove_node(self, node_t node) except -1:
        """
        Remove `node` from the graph.

        Args:
            node: Node to remove.

        Raises:
            KeyError: If the node does not exist.
        """
        if not self._remove_node(node):
            raise KeyError(f"node {node} does not exist")
        IF DEBUG_LOGGING:
            LOGGER.info("removed node %d", node)

    cpdef int remove_nodes_from(self, node_set_t nodes):
        """
        Remove multiple `nodes`.

        Args:
            nodes: Nodes to remove.

        Returns:
            num_removed: Number of nodes removed.

        Note:
            In contrast to :meth:`remove_node`, this method does not raise a :class:`KeyError` if
            `nodes` contains a node that does not exist.
        """
        cdef count_t num_removed = 0
        cdef node_t node
        for node in nodes:
            num_removed += self._remove_node(node)
        return num_removed

    cpdef int has_node(self, node_t node):
        """
        Returns whether `node` exists.

        Args:
            node: Node to check.

        Returns:
            exists: `True` if `node` exists, `False` otherwise.
        """
        return self._adjacency_map.find(node) != self._adjacency_map.end()

    cpdef int number_of_nodes(self):
        """
        Returns the number of nodes.
        """
        return self._adjacency_map.size()

    cpdef int is_directed(self):
        """
        Returns `False` because directed graphs are not supported.
        """
        return False

    cpdef int is_multigraph(self):
        """
        Returns `False` because multigraphs are not supported.
        """
        return False

    cdef int _add_directed_edge(self, node_t source, node_t target):
        return self._adjacency_map[source].insert(target).second

    cdef int _remove_directed_edge(self, node_t source, node_t target):
        it = self._adjacency_map.find(source)
        if it == self._adjacency_map.end():
            return False
        return dereference(it).second.erase(target)

    cpdef int add_edge(self, node_t u, node_t v):
        """
        Add the edge `(u, v)`.

        Args:
            u: First node in the edge pair.
            v: Second node in the edge pair.

        Returns:
            added: `True` if `(u, v)` was added, `False` if it already existed.
        """
        IF DEBUG_LOGGING:
            LOGGER.info("added edge (%d, %d)", u, v)
        return self._add_directed_edge(u, v) and self._add_directed_edge(v, u)

    cpdef int add_edges_from(self, edge_list_t edges):
        """
        Add multiple edges.

        Args:
            edges: Container of pairs of nodes, constituting an edge to be added each.

        Returns:
            num_added: Number of newly added edges.
        """
        cdef count_t num_added = 0
        for edge in edges:
            num_added += self.add_edge(edge.first, edge.second)
        return num_added

    cpdef int _remove_edge(self, node_t u, node_t v):
        return self._remove_directed_edge(u, v) and self._remove_directed_edge(v, u)

    cpdef int remove_edge(self, node_t u, node_t v) except -1:
        """
        Remove the edge `(u, v)`.

        Args:
            u: First node in the edge pair.
            v: Second node in the edge pair.

        Raises:
            KeyError: If the edge between `u` and `v` does not exist.
        """
        if not self._remove_edge(u, v):
            raise KeyError(f"edge {(u, v)} does not exist")
        IF DEBUG_LOGGING:
            LOGGER.info("removed edge (%d, %d)", u, v)

    cpdef int remove_edges_from(self, edge_list_t edges):
        """
        Remove multiple edges.

        Args:
            edges: Container of pairs of nodes, constituting an edge to be removed each.

        Returns:
            num_removed: Number of removed edges.

        Note:
            In contrast to :meth:`remove_edge`, this method does not raise a :class:`KeyError` if
            `edges` contains an edge that does not exist.
        """
        cdef count_t num_removed = 0
        for edge in edges:
            num_removed += self._remove_edge(edge.first, edge.second)

    cpdef int has_edge(self, node_t u, node_t v):
        """
        Returns whether the edge `(u, v)` exists.

        Args:
            u: First node in the edge pair.
            v: Second node in the edge pair.

        Returns:
            exists: `True` if `(u, v)` exists, `False` otherwise.
        """
        it = self._adjacency_map.find(u)
        if it == self._adjacency_map.end():
            return False
        return dereference(it).second.find(v) != dereference(it).second.end()

    cpdef int number_of_edges(self):
        """
        Returns the number of edges.
        """
        cdef int num_edges = 0
        for item in self._adjacency_map:
            num_edges += item.second.size()
        return num_edges // 2


cdef class _View:
    """
    Base class for graph views to expose state to python.
    """
    cdef Graph graph

    def __init__(self, graph: Graph):
        self.graph = graph


cdef class NodeView(_View):
    """
    Node view, yielding nodes.
    """
    def __call__(self):
        return self

    def __iter__(self):
        return iter(self.graph)


cdef class _NodeIterator:
    """
    Dedicated iterator for nodes (see https://stackoverflow.com/q/72426351/1150961).
    """
    cdef Graph graph
    # Using adjacency_map_t.iterator doesn't seem to work.
    cdef unordered_map_t[node_t, unordered_set_t[node_t]].iterator it

    def __init__(self, Graph graph):
        self.graph = graph
        self.it = graph._adjacency_map.begin()

    def __next__(self):
        if self.it == self.graph._adjacency_map.end():
            raise StopIteration
        value = dereference(self.it).first
        preincrement(self.it)
        return value


cdef class EdgeView(_View):
    """
    Edge view yielding tuples of nodes.
    """
    def __call__(self, nbunch=None, data=False, default=None):
        if nbunch is None and data is False:
            return self
        raise NotImplementedError

    def __iter__(self):
        for node in sorted(self.graph._adjacency_map):
            for neighbor in sorted(self.graph._adjacency_map[node]):
                if node <= neighbor:
                    yield (node, neighbor)


cdef class DegreeView(_View):
    """
    Degree view yielding sorted tuples `(node, degree)`. It supports indexing.
    """
    def __getitem__(self, node):
        it = self.graph._adjacency_map.find(node)
        if it != self.graph._adjacency_map.end():
            return dereference(it).second.size()
        raise KeyError(f"node {node} does not exist")

    def __iter__(self):
        for node in sorted(self.graph._adjacency_map):
            yield node, self.graph._adjacency_map[node].size()

    def __call__(self, node=None):
        if node is None:
            return self
        else:
            return self[node]


cdef class NeighborView(_View):
    """
    Neighbor view exposing neighbors using the `__call__` interface.
    """
    def __call__(self, node: node_t):
        it = self.graph._adjacency_map.find(node)
        if it != self.graph._adjacency_map.end():
            return dereference(it).second
        raise KeyError(f"node {node} does not exist")
