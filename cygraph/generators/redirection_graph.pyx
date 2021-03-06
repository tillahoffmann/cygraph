from libcpp.utility cimport move

from ..graph cimport assert_normalized_node_labels, count_t, Graph, node_t, node_list_t, node_set_t
from ..libcpp.algorithm cimport sample
from ..libcpp.random cimport mt19937, bernoulli_distribution, uniform_int_distribution
from ..util import assert_interval
from .util cimport get_random_engine


def redirection_graph(n: count_t, p: float, m: count_t, graph: Graph = None, random_engine=None) \
        -> Graph:
    """
    Redirection graph obtained by selecting random nodes and probabilistically redirecting to their
    neighbors before forming a connection.

    Args:
        n: Number of nodes.
        p: Redirection probability.
        m: Number of stubs for each new node.
        graph: Seed graph; defaults to a graph with a single node.
        random_engine: See :func:`get_random`_engine`.

    Returns:
        graph: Graph generated by the redirection model.

    Note:
        For performance reasons, we sample both candidate nodes (before possible redirection) and
        nodes after redirection with replacement. The realized number of connections for a new node
        may thus be less than :math:`m`.

        This generator is equivalent to the model proposed by [Krapivsky2001]_ implemented by
        :func:`networkx.generators.random_graphs.gnr_graph` if :math:`m = 1`.

    .. [Krapivsky2001] P. L. Krapivsky and S. Redner. Organization of growing random networks.
       *Phys. Rev. E*, 63(6):066123, 2001. https://doi.org/10.1103/PhysRevE.63.066123

    .. plot::

       plot_graph(generators.redirection_graph(20, 0.9, 2))
    """
    cdef uniform_int_distribution[node_t] random_node_dist
    cdef bernoulli_distribution redirection_dist = bernoulli_distribution(p)
    cdef node_t new_node, neighbor
    cdef node_set_t* ptr
    cdef node_list_t neighbors
    cdef mt19937 random_engine_instance = get_random_engine(random_engine).instance
    assert_interval("n", n, 1, None)
    assert_interval("p", p, 0, 1)
    assert_interval("m", m, 1, None)

    if graph is None:
        graph = Graph()
        graph.add_node(0)
    assert_normalized_node_labels(graph)

    while graph.number_of_nodes() < n:
        # Generate the sequence of neighbors by sampling seeds and redirecting proabilistically.
        new_node = graph.number_of_nodes()
        random_node_dist = uniform_int_distribution[node_t](0, new_node - 1)
        neighbors.clear()
        for _ in range(m):
            neighbor = random_node_dist(random_engine_instance)
            if redirection_dist(random_engine_instance):
                ptr = &graph._adjacency_map[neighbor]
                if ptr.size():
                    sample(ptr.begin(), ptr.end(), &neighbor, 1, move(random_engine_instance))
            neighbors.push_back(neighbor)
        # Add the new edges.
        for neighbor in neighbors:
            graph.add_edge(new_node, neighbor)

    return graph
