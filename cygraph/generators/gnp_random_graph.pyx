from ..graph cimport assert_normalized_node_labels, count_t, Graph, node_t
from ..libcpp.random cimport bernoulli_distribution, mt19937
from ..util import assert_interval
from .util cimport get_random_engine


def gnp_random_graph(n: count_t, p: float, graph: Graph = None, random_engine=None) -> Graph:
    r"""
    Erdos-Renyi or :math:`G(n, p)` graph. See
    :func:`networkx.generators.random_graphs.gnp_random_graph` for details.

    Args:
        n: Number of nodes.
        p: Probability to create an edge between any pair nodes.
        graph: Seed graph; defaults to the empty graph.
        random_engine: See :func:`get_random`_engine`.

    Returns:
        graph: Graph generated by the :math:`G(n, p)` model.

    .. plot::

       plot_graph(generators.gnp_random_graph(20, 0.1))
    """
    cdef bernoulli_distribution create_edge = bernoulli_distribution(p)
    cdef node_t u, v
    cdef bint added
    cdef mt19937 random_engine_instance = get_random_engine(random_engine).instance
    assert_interval("p", p, 0, 1)
    assert_interval("n", n, 1, None)

    graph = assert_normalized_node_labels(graph or Graph())

    for u in range(n):
        graph.add_node(u)
        for v in range(u + 1, n):
            if create_edge(random_engine_instance):
                graph.add_edge(u, v)

    return graph
