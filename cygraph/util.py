import contextlib
import numbers
import time
from unittest import mock
from .graph import Graph


def plot_graph(graph: Graph, seed: int = 0, ax=None) -> None:
    """
    Plot a graph.

    Args:
        graph: Graph to plot.
        seed: Random number generator seed for the spring layout.
    """
    from matplotlib import pyplot as plt
    import networkx as nx

    if ax is None:
        fig, ax = plt.subplots()
    else:
        fig = None
    # Explicitly convert to networkx graph because `spring_layout` implicitly depends on data.
    graph = nx.Graph(graph.adj)
    pos = nx.spring_layout(graph, seed=seed)
    nx.draw_networkx_edges(graph, pos, edge_color='gray')
    nx.draw_networkx_nodes(graph, pos, node_color='#7fbde9', edgecolors='C0')
    nx.draw_networkx_labels(graph, pos)
    ax.set_aspect('equal')
    ax.set_axis_off()
    if fig is not None:
        fig.tight_layout()


def assert_interval(name: str, value: numbers.Number, low: numbers.Number, high: numbers.Number,
                    inclusive_low: bool = True, inclusive_high: bool = True) -> None:
    """
    Assert that a value falls in a certain interval.

    Args:
        name: Name of the variable for the error message.
        value: Value to check.
        low: Lower limit of the interval.
        high: Upper limit of the interval.
        inclusive_low: Whether the lower limit of the interval is inclusive.
        inclusive_high: Whether the upper limit of the interval is inclusive.

    Raises:
        ValueError: If the value does not fall in the interval.
    """
    outside = (
        low is not None
        and ((value < low and inclusive_low) or (value <= low and not inclusive_low))
    ) or (
        high is not None
        and ((value > high) and inclusive_high or (value >= high and not inclusive_high))
    )
    if outside:
        raise ValueError(f"{name} must belong to the interval {'[' if inclusive_low else '('}"
                         f"{'-inf' if low is None else low}, {'inf' if high is None else high}"
                         f"{']' if inclusive_high else ')'} but got {value}")


class Timer:
    """
    Simple timer that can be used as a context.
    """
    def __init__(self):
        self.start = None
        self.end = None

    def __enter__(self):
        self.start = time.time()
        return self

    def __exit__(self, *_):
        self.end = time.time()

    @property
    def duration(self) -> float:
        """
        Duration for which the context was active.
        """
        if self.start is None:
            raise ValueError("timer has not yet been started")  # pragma: no cover
        return (self.end or time.time()) - self.start


@contextlib.contextmanager
def patch_nx_graph():
    """
    Context for patching :class:`networkx.Graph` and :func:`networkx.empty_graph` so they return
    :class:`Graph` instances.
    """
    from .graph import Graph
    with mock.patch("networkx.empty_graph.__defaults__", (0, None, Graph)), \
            mock.patch("networkx.Graph", Graph):
        yield
