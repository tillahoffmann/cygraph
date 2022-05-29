from .graph cimport Graph, node_t, node_set_t
from .libcpp.random cimport bernoulli_distribution, mt19937, random_device
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


def duplication_divergence_graph(n: int, p: float, graph: Graph = None,
                                 random_engine: RandomEngine = None) -> Graph:
    cdef bernoulli_distribution retention_dist = bernoulli_distribution(p)
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
