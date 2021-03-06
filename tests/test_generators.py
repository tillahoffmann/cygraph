from cygraph import generators
import networkx as nx
import pytest
from scipy import stats
import typing
from unittest import mock


def test_random_engine():
    engine = generators.get_random_engine()
    assert isinstance(engine, generators.RandomEngine)
    assert isinstance(engine(), int)
    engine = generators.get_random_engine(3)
    assert engine() == 2365658986
    assert generators.get_random_engine(engine) is engine
    with pytest.raises(ValueError):
        generators.get_random_engine("invalid value")

    # Explicitly test with and without environment variables.
    with mock.patch("os.environ.get", return_value=None):
        # Just test we can create it and check coverage after.
        generators.RandomEngine()
    with mock.patch("os.environ.get", return_value="3"):
        engine = generators.RandomEngine()
        assert engine() == 2365658986


@pytest.mark.parametrize("random_engine", [None, 17, generators.get_random_engine(9)])
@pytest.mark.parametrize("num_nodes", [100, 1000])
@pytest.mark.parametrize("generator, kwargs, connected", [
    # This graph is guaranteed to be connected.
    (generators.duplication_mutation_graph,
     {"deletion_proba": 0.5, "mutation_proba": 0.5, "drop_isolates": True}, True),
    # This graph is not guaranteed to be disconnected, but should be with high probability.
    (generators.duplication_mutation_graph,
     {"deletion_proba": 0.99, "mutation_proba": 0.01, "drop_isolates": False}, False),
    # This graph is not guaranteed to be connected, but should be with high probability.
    (generators.duplication_mutation_graph,
     {"deletion_proba": 0.01, "mutation_proba": .99, "drop_isolates": True}, True),
    # This graph is not guaranteed to be connected, but should be with high probability.
    (generators.duplication_complementation_graph,
     {"deletion_proba": 0.01, "interaction_proba": 0.99}, True),
    # This graph is not guaranteed to be disconnected, but should be with high probability.
    (generators.duplication_complementation_graph,
     {"deletion_proba": 0.99, "interaction_proba": 0.01}, False),
    # This graph is not guaranteed to be connected, but should be with high probability.
    (generators.gnp_random_graph, {"p": 0.9}, True),
    # This graph is not guaranteed to be disconnected, but should be with high probability.
    (generators.gnp_random_graph, {"p": 1e-3}, False),
    # This graph is guaranteed to be connected.
    (generators.surfer_graph, {"connection_proba": 0.3}, True),
])
def test_generators(random_engine: int, num_nodes: int, generator: typing.Callable, kwargs: dict,
                    connected: bool):
    graph = generator(num_nodes, **kwargs, random_engine=random_engine)
    assert graph.number_of_nodes() == num_nodes
    if connected is not None:
        assert nx.is_connected(graph) == connected
    assert (loops := nx.number_of_selfloops(graph)) == 0, f"graph has {loops} self loops"

    if generator is generators.gnp_random_graph:
        dist = stats.binom(num_nodes * (num_nodes - 1) // 2, kwargs["p"])
        pval = dist.cdf(graph.number_of_edges())
        pval = min(pval, 1 - pval)
        assert pval > 0.001
