from cygraph import generators
import networkx as nx
import pytest
from scipy import stats


def test_random_engine():
    engine = generators.get_random_engine()
    assert isinstance(engine, generators.RandomEngine)
    assert isinstance(engine(), int)
    engine = generators.get_random_engine(3)
    assert engine() == 2365658986
    assert generators.get_random_engine(engine) is engine
    with pytest.raises(ValueError):
        generators.get_random_engine("invalid value")


@pytest.mark.parametrize("args", [(.3,), (.3, .4)])
def test_duplication_divergence(args):
    graph = generators.duplication_divergence_graph(100, *args)
    assert graph.number_of_nodes() == 100
    assert all(k for _, k in graph.degree)
    assert nx.is_connected(graph)


@pytest.mark.parametrize("generator", [
    # generators.fast_gnp_random_graph,
    generators.gnp_random_graph,
])
@pytest.mark.parametrize("n, p", [(1000, 0.01), (10, 0.5)])
def test_x_gnp_random_graph(generator, n, p):
    graph = generator(n, p)
    dist = stats.binom(n * (n - 1) // 2, p)
    pval = dist.cdf(graph.number_of_edges())
    pval = min(pval, 1 - pval)
    assert pval > 0.01
