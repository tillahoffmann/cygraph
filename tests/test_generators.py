from cygraph import generators


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
