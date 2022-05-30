from cygraph.scripts import performance_experiments


def test_performance_experiments():
    results = performance_experiments.__main__(["--num_repeats=1"])
    assert isinstance(results, dict)
