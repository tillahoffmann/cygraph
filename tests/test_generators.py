from cygraph import generators
import networkx as nx
import pytest
from scipy import stats
import typing


def test_random_engine():
    engine = generators.get_random_engine()
    assert isinstance(engine, generators.RandomEngine)
    assert isinstance(engine(), int)
    engine = generators.get_random_engine(3)
    assert engine() == 2365658986
    assert generators.get_random_engine(engine) is engine
    with pytest.raises(ValueError):
        generators.get_random_engine("invalid value")


@pytest.mark.parametrize("num_nodes", [100, 1000])
@pytest.mark.parametrize("generator, kwargs, connected", [
    (generators.duplication_mutation_graph, {"deletion_proba": 0.5, "mutation_proba": 0.5}, True),
    (generators.duplication_complementation_graph,
     {"deletion_proba": 0.5, "interaction_proba": 0.5}, True),
    (generators.gnp_random_graph, {"p": 0.9}, True),
    (generators.gnp_random_graph, {"p": 1e-3}, False),
])
def test_generators(num_nodes: int, generator: typing.Callable, kwargs: dict, connected: bool):
    graph = generator(num_nodes, **kwargs)
    assert graph.number_of_nodes() == num_nodes
    if connected is not None:
        assert nx.is_connected(graph) == connected

    if generator is generators.gnp_random_graph:
        dist = stats.binom(num_nodes * (num_nodes - 1) // 2, kwargs["p"])
        pval = dist.cdf(graph.number_of_edges())
        pval = min(pval, 1 - pval)
        assert pval > 0.001
