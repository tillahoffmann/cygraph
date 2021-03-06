import cygraph
import functools as ft
import itertools as it
import logging
import networkx as nx
import numbers
import pytest
import random
import typing
from unittest import mock


skip_multigraph = pytest.mark.skip("multigraphs are not supported")
skip_non_integer_labels = pytest.mark.skip("requires non-integer labels")
skip_requires_attributes = pytest.mark.skip("requires attributes")
order_dependent_generators = {
    nx.gnm_random_graph, nx.powerlaw_cluster_graph, nx.extended_barabasi_albert_graph,
    nx.newman_watts_strogatz_graph, nx.duplication_divergence_graph,
}


def sorted_edges(edges):
    return list(sorted((min(u, v), max(u, v)) for u, v in edges))


def assert_same_graph(graph1, graph2):
    assert set(graph1) == set(graph2)
    assert set(sorted_edges(graph1.edges)) == set(sorted_edges(graph2.edges))


@pytest.mark.parametrize("generator, kwargs", [
    # Classic graph generators.
    (nx.generators.balanced_tree, {"r": 2, "h": 10}),
    (nx.generators.barbell_graph, {"m1": 7, "m2": 13}),
    (nx.generators.binomial_tree, {"n": 7}),
    (nx.generators.complete_graph, {"n": 100}),
    (nx.generators.circular_ladder_graph, {"n": 17}),
    (nx.generators.circulant_graph, {"n": 23, "offsets": [3]}),
    (nx.generators.cycle_graph, {"n": 17}),
    (nx.generators.dorogovtsev_goltsev_mendes_graph, {"n": 2}),
    (nx.generators.empty_graph, {"n": 19}),
    (nx.generators.full_rary_tree, {"r": 5, "n": 31}),
    (nx.generators.ladder_graph, {"n": 37}),
    (nx.generators.lollipop_graph, {"m": 5, "n": 7}),
    (nx.generators.null_graph, {}),
    (nx.generators.path_graph, {"n": 13}),
    (nx.generators.star_graph, {"n": 11}),
    (nx.generators.trivial_graph, {}),
    pytest.param(nx.turan_graph, {"n": 7, "r": 3}, marks=skip_multigraph),
    (nx.generators.wheel_graph, {"n": 17}),
    # Expanders graphs.
    pytest.param(nx.generators.margulis_gabber_galil_graph, {"n": 15}, marks=skip_multigraph),
    pytest.param(nx.generators.chordal_cycle_graph, {"p": 9}, marks=skip_multigraph),
    pytest.param(nx.generators.paley_graph, {"p": 17}, marks=skip_requires_attributes),
    # Lattice graphs.
    pytest.param(nx.generators.grid_2d_graph, {"m": 10, "n": 7}, marks=skip_non_integer_labels),
    pytest.param(nx.generators.grid_graph, {"dim": [7, 8, 9]}, marks=skip_non_integer_labels),
    pytest.param(nx.generators.hexagonal_lattice_graph, {"m": 10, "n": 3},
                 marks=skip_non_integer_labels),
    pytest.param(nx.generators.hypercube_graph, {"n": 3}),
    pytest.param(nx.generators.triangular_lattice_graph, {"m": 5, "n": 2}),
    # Small graphs.
    (nx.generators.LCF_graph, {"n": 6, "shift_list": [3, -3], "repeats": 3}),
    (nx.generators.bull_graph, {}),
    (nx.generators.chvatal_graph, {}),
    pytest.param(nx.generators.cubical_graph, {}, marks=pytest.mark.skip("non-string name")),
    (nx.generators.desargues_graph, {}),
    (nx.generators.diamond_graph, {}),
    (nx.generators.dodecahedral_graph, {}),
    (nx.generators.frucht_graph, {}),
    (nx.generators.heawood_graph, {}),
    pytest.param(nx.generators.hoffman_singleton_graph, {}, marks=skip_non_integer_labels),
    (nx.generators.house_graph, {}),
    (nx.generators.house_x_graph, {}),
    (nx.generators.icosahedral_graph, {}),
    (nx.generators.krackhardt_kite_graph, {}),
    (nx.generators.moebius_kantor_graph, {}),
    (nx.generators.octahedral_graph, {}),
    pytest.param(nx.generators.pappus_graph, {}),
    (nx.generators.petersen_graph, {}),
    (nx.generators.sedgewick_maze_graph, {}),
    (nx.generators.tetrahedral_graph, {}),
    (nx.generators.truncated_cube_graph, {}),
    (nx.generators.truncated_tetrahedron_graph, {}),
    (nx.generators.tutte_graph, {}),
    # Random graphs.
    (nx.fast_gnp_random_graph, {"n": 20, "p": 0.2, "seed": 0}),
    (nx.gnp_random_graph, {"n": 20, "p": 0.2, "seed": 0}),
    (nx.dense_gnm_random_graph, {"n": 30, "m": 4, "seed": 0}),
    (nx.gnm_random_graph, {"n": 30, "m": 4, "seed": 0}),
    (nx.newman_watts_strogatz_graph, {"n": 50, "k": 5, "p": 0.1, "seed": 0}),
    (nx.watts_strogatz_graph, {"n": 50, "k": 5, "p": 0.1, "seed": 0}),
    (nx.connected_watts_strogatz_graph, {"n": 50, "k": 5, "p": 0.1, "seed": 0}),
    (nx.random_regular_graph, {"d": 5, "n": 20, "seed": 0}),
    (nx.barabasi_albert_graph, {"n": 40, "m": 3, "seed": 0}),
    (nx.dual_barabasi_albert_graph, {"n": 40, "m1": 3, "m2": 2, "p": 0.1, "seed": 0}),
    (nx.extended_barabasi_albert_graph, {"n": 6, "m": 3, "p": 0.1, "q": 0.2, "seed": 1}),
    (nx.powerlaw_cluster_graph, {"n": 30, "m": 3, "p": 0.1, "seed": 0}),
    (nx.random_lobster, {"n": 40, "p1": 0.1, "p2": 0.2, "seed": 0}),
    pytest.param(nx.random_shell_graph, {"constructor": [(10, 20, 0.8), (20, 40, 0.8)], "seed": 0},
                 marks=pytest.mark.skip("uses private properties, not public API")),
    (nx.random_powerlaw_tree, {"n": 10, "seed": 14, "tries": 1}),
    (nx.random_kernel_graph, {"n": 10, "kernel_integral": lambda u, w, z: z - w,
                              "kernel_root": lambda u, w, r: r + w, "seed": 0}),
    (nx.duplication_divergence_graph, {"n": 17, "p": 0.1, "seed": 0}),
    (nx.partial_duplication_graph, {"N": 20, "n": 3, "p": 0.2, "q": 0.3, "seed": 0}),
])
def test_networkx_generators(generator: typing.Callable, kwargs: dict):
    graph1 = generator(**kwargs)
    if any(not isinstance(node, numbers.Integral) for node in graph1):
        pytest.skip("requires non-integer labels")

    patched_empty_graph = ft.partial(nx.empty_graph, default=cygraph.Graph)
    if generator is nx.empty_graph:
        graph2 = patched_empty_graph(**kwargs)
    else:
        with cygraph.util.patch_nx_graph():
            graph2 = generator(**kwargs)
    assert isinstance(graph1, nx.Graph)
    assert isinstance(graph2, cygraph.Graph)
    for graph in [graph1, graph2]:
        graph.number_of_nodes() == len(list(graph.nodes))
        graph.number_of_edges() == len(list(graph.edges()))

    # These generators depend on the non-deterministic node order, and we skip exact checks.
    if generator in order_dependent_generators:
        return

    assert graph1.number_of_nodes() == graph2.number_of_nodes()
    assert graph1.number_of_edges() == graph2.number_of_edges()
    assert graph1.size() == graph2.size()
    assert len(graph1) == len(graph2)
    assert_same_graph(graph1, graph2)


@pytest.fixture
def graph_pair():
    kwargs = {"n": 100, "p": 0.02, "seed": 1}
    graph1 = nx.erdos_renyi_graph(**kwargs)

    patched_empty_graph = ft.partial(nx.empty_graph, default=cygraph.Graph)
    with mock.patch("networkx.generators.random_graphs.empty_graph", patched_empty_graph):
        graph2 = nx.erdos_renyi_graph(**kwargs)
    return graph1, graph2


def test_connected_components(graph_pair):
    cc1, cc2 = [
        {tuple(sorted(component)) for component in nx.connected_components(graph)}
        for graph in graph_pair
    ]
    assert cc1 == cc2


def test_subgraph(graph_pair):
    graph1, graph2 = graph_pair
    subset = random.sample(list(graph1), len(graph1) // 2)
    assert_same_graph(nx.subgraph(graph1, subset), nx.subgraph(graph2, subset))


def test_shortest_paths(graph_pair):
    paths1, paths2 = [dict(nx.all_pairs_shortest_path(graph)) for graph in graph_pair]
    assert paths1 == paths2


@pytest.fixture(params=[nx.Graph, cygraph.Graph], ids=["nx", "cygraph"])
def graph_cls(request: pytest.FixtureRequest):
    return request.param


@pytest.fixture
def triangle_graph(graph_cls):
    graph = graph_cls()
    graph.add_edges_from([(0, 1), (0, 2), (1, 2)])
    return graph


def test_get_set_name(triangle_graph: nx.Graph):
    assert triangle_graph.name == "" or triangle_graph.name is None
    triangle_graph.name = "name"
    assert triangle_graph.name == "name"


def test_remove_connected_node(triangle_graph: nx.Graph):
    assert all(k == 2 for _, k in triangle_graph.degree)
    triangle_graph.remove_node(0)
    assert not triangle_graph.has_node(0)
    with pytest.raises(KeyError):
        triangle_graph.degree[0]
    assert set(triangle_graph) == {1, 2}
    for node in triangle_graph:
        assert 0 not in triangle_graph.neighbors(node)


def test_has_node(triangle_graph: nx.Graph):
    assert 0 in triangle_graph
    assert triangle_graph.has_node(0)

    assert 7 not in triangle_graph
    assert not triangle_graph.has_node(7)


def test_degree_view(triangle_graph: nx.Graph):
    with pytest.raises(KeyError):
        triangle_graph.degree[99]
    triangle_graph.add_node(99)
    assert triangle_graph.degree[99] == 0


def test_neighbor_view(triangle_graph: nx.Graph):
    with pytest.raises((KeyError, nx.NetworkXError)):
        triangle_graph.neighbors(99)
    triangle_graph.add_node(99)
    assert set(triangle_graph.neighbors(99)) == set()


def test_remove_nodes_from(triangle_graph: nx.Graph):
    triangle_graph.remove_nodes_from([0, 1])
    assert set(triangle_graph) == {2}
    triangle_graph.remove_nodes_from({2, 3})
    assert len(triangle_graph) == 0


def test_remove_missing_node(triangle_graph: nx.Graph):
    with pytest.raises((KeyError, nx.NetworkXError)):
        triangle_graph.remove_node(99)
    triangle_graph.remove_nodes_from([99])


def test_remove_missing_edge(triangle_graph: nx.Graph):
    assert not triangle_graph.has_edge(99, 98)
    with pytest.raises((KeyError, nx.NetworkXError)):
        triangle_graph.remove_edge(99, 98)
    with pytest.raises((KeyError, nx.NetworkXError)):
        triangle_graph.remove_edge(0, 99)
    triangle_graph.remove_edges_from([(99, 98)])


@pytest.mark.parametrize("name", ["nodes", "edges", "degree", "__self__"])
def test_views(name: str):
    density = 0.1
    num_nodes = 100
    num_edges = int(num_nodes * (num_nodes - 1) / 2 * density)
    nodes = random.sample(range(10 * num_nodes), num_nodes)
    edges = random.sample(list(it.combinations(nodes, 2)), num_edges)

    graphs = []
    for cls in [nx.Graph, cygraph.Graph]:
        graph = cls()
        graph.add_nodes_from(nodes)
        graph.add_edges_from(edges)
        graphs.append(graph)

    attrs = [graph if name == "__self__" else getattr(graph, name) for graph in graphs]
    if name == "edges":
        attrs = [sorted_edges(edges) for edges in attrs]
    else:
        attrs = [list(sorted(attr)) for attr in attrs]
    attr1, attr2 = attrs
    assert attr1 == attr2


@pytest.mark.skipif(not cygraph.DEBUG_LOGGING, reason="debug logging not enabled")
def test_debug_logging_add_remove_node(caplog: pytest.LogCaptureFixture):
    graph = cygraph.Graph()
    with caplog.at_level(logging.DEBUG):
        graph.add_node(17)
        graph.remove_node(17)
    assert "added node 17" in caplog.text
    assert "removed node 17" in caplog.text


@pytest.mark.skipif(not cygraph.DEBUG_LOGGING, reason="debug logging not enabled")
def test_debug_logging_add_remove_edge(caplog: pytest.LogCaptureFixture):
    graph = cygraph.Graph()
    with caplog.at_level(logging.DEBUG):
        graph.add_edge(0, 7)
        graph.remove_edge(0, 7)
    assert "added edge (0, 7)" in caplog.text
    assert "removed edge (0, 7)" in caplog.text


def test_complex_edge_view():
    graph = cygraph.Graph()
    with pytest.raises(NotImplementedError):
        graph.edges(nbunch=[0])
    with pytest.raises(NotImplementedError):
        graph.edges(data=True)


def test_graph_init():
    nodes = {0, 1, 2, 3}
    edges = {(0, 1), (1, 2), (0, 2)}
    reference = cygraph.Graph()
    reference.add_nodes_from(nodes)
    reference.add_edges_from(edges)
    assert_same_graph(reference, cygraph.Graph(nodes, edges))


def test_graph_init_copy():
    graph = cygraph.Graph()
    graph.add_edge(0, 1)
    copy = cygraph.Graph(graph)
    copy.add_edge(0, 2)
    assert not graph.has_edge(0, 2)


@pytest.mark.parametrize("graph, failing", [
    (cygraph.Graph({0, 1, 2}), False),
    (cygraph.Graph({-1, 0, 1}), True),
    (cygraph.Graph({1, 2}), True),
    (cygraph.Graph({0, 2}), True),
])
def test_assert_normalized_node_labels(graph: cygraph.Graph, failing: bool):
    if failing:
        with pytest.raises(ValueError):
            cygraph.graph.assert_normalized_node_labels(graph)
    else:
        assert cygraph.graph.assert_normalized_node_labels(graph) is graph
