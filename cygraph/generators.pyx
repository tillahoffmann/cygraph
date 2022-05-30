from .graph cimport Graph, node_t
from .libcpp.random cimport bernoulli_distribution, mt19937, random_device, uniform_real_distribution
from libc cimport math
from libcpp.utility cimport move
import numbers
from .util import assert_interval


cdef class RandomEngine:
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


cpdef RandomEngine get_random_engine(engine_seed_or_none: int = None):
    if engine_seed_or_none is None:
        return DEFAULT_RANDOM_ENGINE
    elif isinstance(engine_seed_or_none, RandomEngine):
        return engine_seed_or_none
    else:
        return RandomEngine(engine_seed_or_none)


def duplication_divergence_graph(int n, float p, Graph graph = None,
                                 RandomEngine random_engine = None) -> Graph:
    cdef bernoulli_distribution retention_dist = bernoulli_distribution(p)
    cdef node_t i, random_node
    assert_interval("p", p, 0, 1)
    assert_interval("n", n, 2, None)
    random_engine = get_random_engine(random_engine)

    if not graph:
        graph = Graph()
        graph.add_edge(0, 1)

    while graph.number_of_nodes() < n:
        i = graph.number_of_nodes()
        # Choose a random node from current graph to duplicate.
        random_node = random_engine.instance() % i
        # Duplicate links independently with the given probability.
        for neighbor in graph._adjacency_map[random_node]:
            if retention_dist(random_engine.instance):
                graph.add_edge(i, neighbor)
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


def gnp_random_graph(int n, float p, Graph graph = None, RandomEngine random_engine = None):
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
