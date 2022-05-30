import argparse
from cygraph.util import patch_nx_graph
from cygraph import generators
import functools as ft
import networkx as nx
import numpy as np
from tqdm import tqdm
import typing
from ..util import Timer


def evaluate_durations(generator: typing.Callable, max_duration: float, num_nodes: int,
                       desc: str = None) -> typing.List[float]:
    durations = []
    with Timer() as batch_timer, tqdm(desc=desc) as progress:
        while batch_timer.duration < max_duration:
            with Timer() as timer:
                generator(num_nodes)
            durations.append(timer.duration)
            progress.update()
    return durations


def patched(func):
    """
    Decorator for patching `networkx` functions and types with their `cygraph` equivalents. See
    :func:`..util.patch_nx_graph` for details.
    """
    @ft.wraps(func)
    def _wrapper(*args, **kwargs):
        with patch_nx_graph():
            func(*args, **kwargs)
    return _wrapper


def __main__(args: list[str] = None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--max_duration", type=float, default=1,
                        help="maximum duration generating graphs for each generator")
    parser.add_argument("num_nodes", help="number of nodes for each graph", type=int)
    args = parser.parse_args(args)

    # Sequence of `(nx generator, cygraph generator if available, kwargs)`.
    configurations = {
        "duplication_mutation_graph": {
            "networkx": ft.partial(nx.duplication_divergence_graph, p=0.3),
            "patched": patched(ft.partial(nx.duplication_divergence_graph, p=0.3)),
            "cygraph": ft.partial(generators.duplication_mutation_graph, deletion_proba=0.7,
                                  mutation_proba=0),
        },
        "gnp_random_graph": {
            "networkx": ft.partial(nx.gnp_random_graph, p=10 / args.num_nodes),
            "patched": patched(ft.partial(nx.gnp_random_graph, p=10 / args.num_nodes)),
            "cygraph": ft.partial(generators.gnp_random_graph, p=10 / args.num_nodes),
        }
    }

    # Evaluate duration samples.
    durations_by_config_and_method = {}
    for config_key, methods in configurations.items():
        durations_by_method = {
            key: evaluate_durations(method, args.max_duration, args.num_nodes,
                                    desc=f"{config_key}.{key}") for key, method in methods.items()
        }
        durations_by_config_and_method[config_key] = durations_by_method

        # Report as soon as we have the results.
        counts = {key: len(durations) for key, durations in durations_by_method.items()}
        mean_durations = {key: np.mean(durations) for key, durations in durations_by_method.items()}
        factors = {key: mean_durations["networkx"] / mean_duration for key, mean_duration
                   in mean_durations.items() if key != "networkx"}

        line = "; ".join(f"{key} ({counts[key]} runs): {factor:.3f}x" for key, factor in
                         factors.items())
        print(f"{config_key} -- {line}")

    return durations_by_config_and_method


if __name__ == "__main__":
    __main__()
