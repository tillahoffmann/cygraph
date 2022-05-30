# cython: cdivision = True

from .graph cimport count_t, Graph, node_t, node_list_t
from .libcpp.random cimport bernoulli_distribution, binomial_distribution, mt19937, random_device, \
    uniform_int_distribution, uniform_real_distribution
from libc cimport math
from libcpp.utility cimport move
import numbers
from .util import assert_interval
import typing


cdef class RandomEngine:
    """
    Mersenne Twister pseudo-random generator of 32-bit numbers with a state size of 19937 bits.

    Args:
        seed: Random number generator seed; defaults to a call to
            `random_device <https://en.cppreference.com/w/cpp/numeric/random/random_device>`_.
    """
    cdef mt19937 instance

    def __init__(self, seed: int = None):
        cdef random_device rd
        if seed is None:
            self.instance = mt19937(rd())
        else:
            self.instance = mt19937(seed)

    def __call__(self):
        return self.instance()


DEFAULT_RANDOM_ENGINE = RandomEngine()


cpdef RandomEngine get_random_engine(arg: typing.Optional[typing.Union[int, RandomEngine]] = None):
    """
    Utility function to get a random engine.

    Args:
        arg: One of `None`, an integer seed, or a :class:`RandomEngine`. If `None`, a default,
            global random engine is returned. If an integer seed, a newly seeded random engine is
            returned. If a :class:`RandomEngine`, it is passed through.

    Returns:
        random_engine: Initialized :class:`RandomEngine` instance.
    """
    if arg is None:
        return DEFAULT_RANDOM_ENGINE
    elif isinstance(arg, RandomEngine):
        return arg
    elif isinstance(arg, numbers.Integral):
        return RandomEngine(arg)
    else:
        raise ValueError(arg)


def duplication_divergence_graph(n: int, retention_proba: float, mutation_proba: float = 0,
                                 graph: Graph = None, random_engine: RandomEngine = None) -> Graph:
    r"""
    Duplication divergence graph with random mutations as described by
    `Sole et al. (2002) <Sole2002>`_. Equivalent to
    :func:`networkx.generators.duplication.duplication_divergence_graph` if :math:`\beta = 0`.

    Args:
        n: Number of nodes.
        retention_proba: Probability that an edge is duplicated. The parameter is denoted
            :math:`1 - \delta` in `Sole et al. (2002) <Sole2002>`_, where :math:`\delta` is the edge
            deletion probability.
        mutation_proba: Scaled mutation probability such that a random connection between the new
            node and existings node are created with probability :math:`\beta / t`.
        graph: Seed graph; defaults to a pair of connected nodes.
        random_engine: See :func:`get_random_engine`.

    Returns:
        graph: Graph generated by the duplication divergence model.

    The growth process proceeds in three stages at each step :math:`t`:

    1. A node :math:`i` is chosen at random and duplicated to obtain a new node :math:`t`.
    2. For each neighbor :math:`j` of :math:`i`, a connection to the new node :math:`t` is added
       with probability `retention_proba`.
    3. Connections between the new node :math:`t` and any other nodes in the network are created
       with probability :math:`\beta / t`, where :math:`\beta` is `mutation_proba`.

    Note:
        In the third step, we sample the number of additional edges :math:`k` from a binomial random
        variable with :math:`t - 1` trials and probability :math:`\min\left(1, \beta / t\right)`. We
        then sample :math:`k` neighbors with replacement and connect them to :math:`t`. The actual
        number of additional connections may thus be smaller than :math:`k`, especially when the
        graph is small. This compromise avoids relatively expensive sampling without replacement
        from the population of nodes.

    .. Sole2002: https://doi.org/10.1142/S021952590200047X
    """
    cdef bernoulli_distribution retention_dist = bernoulli_distribution(retention_proba)
    cdef binomial_distribution[count_t] num_additional_neighbors_dist
    cdef count_t num_additional_neighbors
    cdef uniform_int_distribution[node_t] random_node_dist
    cdef node_list_t additional_neighbors
    cdef node_t new_node, random_neighbor, seed_node
    assert_interval("n", n, 2, None)
    assert_interval("retention_proba", retention_proba, 0, 1)
    assert_interval("mutation_proba", mutation_proba, 0, None)
    random_engine = get_random_engine(random_engine)

    if not graph:
        graph = Graph()
        graph.add_edge(0, 1)

    while graph.number_of_nodes() < n:
        new_node = graph.number_of_nodes()
        # Choose a random node from current graph to duplicate.
        random_node_dist = uniform_int_distribution[node_t](0, new_node - 1)
        seed_node = random_node_dist(random_engine.instance)
        # Relatively cheap check to avoid constructing distributions if we don't need them.
        if mutation_proba > 0:
            # Identify nodes connected by random mutation.
            num_additional_neighbors_dist = binomial_distribution[count_t](
                new_node - 1, min(mutation_proba / new_node, 1))
            num_additional_neighbors = num_additional_neighbors_dist(random_engine.instance)
            additional_neighbors.clear()
            for _ in range(num_additional_neighbors):
                additional_neighbors.push_back(random_node_dist(random_engine.instance))
        # Duplicate links independently with the given probability.
        for neighbor in graph._adjacency_map[seed_node]:
            if retention_dist(random_engine.instance):
                graph.add_edge(new_node, neighbor)

        for neighbor in additional_neighbors:
            graph.add_edge(new_node, neighbor)
    return graph


# This generator is currently commented out because it behaves strangely (see TODO note below).
# def fast_gnp_random_graph(int n, float p, Graph graph = None, RandomEngine random_engine = None) \
#         -> Graph:
#     cdef uniform_real_distribution[float] uniform = uniform_real_distribution[float](0, 1)
#     cdef node_t v, w
#     assert_interval("p", p, 0, 1)
#     assert_interval("n", n, 1, None)
#     random_engine = get_random_engine(random_engine)
#
#     if not graph:
#         graph = Graph()
#     for i in range(n):
#         graph.add_node(i)
#
#     lp = math.log1p(-p)
#
#     v = 1
#     w = -1
#     while v < n:
#         # TODO: why does this behaves different from random.random and is sometimes *really* slow?
#         lr = math.log1p(-uniform(random_engine.instance))
#         w = w + 1 + <node_t>math.floor(lr / lp)
#         while w >= v and v < n:
#             w = w - v
#             v = v + 1
#         if v < n:
#             graph.add_edge(v, w)
#     return graph


def gnp_random_graph(n: int, p: float, graph: Graph = None, random_engine: RandomEngine = None) \
        -> Graph:
    r"""
    Erdos-Renyi or :math:`G(n, p)` graph. See
    :func:`networkx.generators.random_graphs.gnp_random_graph` for details.

    Args:
        n: Number of nodes.
        p: Probability to create an edge between any pair nodes.
        graph: Seed graph; defaults to the empty graph.
        random_engine: See :func:`get_random_engine`.

    Returns:
        graph: Graph generated by the :math:`G(n, p)` model.
    """
    cdef bernoulli_distribution create_edge = bernoulli_distribution(p)
    cdef node_t u, v
    cdef bint added
    assert_interval("p", p, 0, 1)
    assert_interval("n", n, 1, None)
    random_engine = get_random_engine(random_engine)

    graph = graph or Graph()

    for u in range(n):
        graph.add_node(u)
        for v in range(u + 1, n):
            if create_edge(random_engine.instance):
                graph.add_edge(u, v)

    return graph
