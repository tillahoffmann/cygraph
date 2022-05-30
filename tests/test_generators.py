from cygraph import generators
import pytest
from scipy import stats


def test_random_engine():
    engine = generators.get_random_engine()
    assert isinstance(engine, generators.RandomEngine)
    assert isinstance(engine(), int)
    engine = generators.get_random_engine(3)
    assert engine() == 2365658986
    assert generators.get_random_engine(engine) is engine


def test_duplication_divergence():
    graph = generators.duplication_divergence_graph(100, .3)
    assert graph.number_of_nodes() == 100
    assert all(k for _, k in graph.degree)


@pytest.mark.parametrize("generator", [
    # generators.fast_gnp_random_graph,
    generators.gnp_random_graph,
])
@pytest.mark.parametrize("n, p", [(10000, 0.001), (10, 0.5)])
def test_x_gnp_random_graph(generator, n, p):
    graph = generator(n, p)
    dist = stats.binom(n * (n - 1) // 2, p)
    pval = dist.cdf(graph.number_of_edges())
    pval = min(pval, 1 - pval)
    assert pval > 0.01
