from cygraph import generators, util
from matplotlib import pyplot as plt
import pytest


@pytest.mark.parametrize("fail, args", [
    (False, (0.5, 0, 1)),  # General check.
    (True, (-1, 1.1, 2)),  # Outside to the left.
    (False, (0, 0, 1)),  # Left bound inclusive.
    (True, (0, 0, 1, False)),  # Left bound exclusive.
    (False, (-1000, None, 1)),  # Unbounded left.
    (True, (2, None, 1)),  # Unbounded left, outside to the right.
    (True, (2.5, 1.1, 2)),  # Outside to the right.
    (False, (1, 0, 1)),  # Right bound inclusive.
    (True, (1, 0, 1, True, False)),  # Right bound inclusive.
    (False, (1000, 10, None)),  # Unbounded right.
    (True, (3, 10, None)),  # Unbounded right, outside to the left.
])
def test_assert_interval(fail, args):
    if fail:
        with pytest.raises(ValueError):
            util.assert_interval("var", *args)
    else:
        util.assert_interval("var", *args)


def test_plot_graph():
    util.plot_graph(generators.gnp_random_graph(10, 0.1))
    fig, ax = plt.subplots()
    util.plot_graph(generators.gnp_random_graph(10, 0.1), ax=ax)
