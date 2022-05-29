import argparse
from cygraph.graph import patch_nx_graph
from cygraph import generators
import networkx as nx
import numpy as np
import time


def evaluate_durations(generator, max_duration, kwargs):
    durations = []
    batch_start = time.time()
    while time.time() - batch_start < max_duration:
        start = time.time()
        generator(**kwargs)
        durations.append(time.time() - start)
    return durations


def __main__(args: list[str] = None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--max_duration", type=float, default=1,
                        help="maximum duration generating graphs for each generator")
    parser.add_argument("num_nodes", help="number of nodes for each graph", type=int)
    args = parser.parse_args(args)

    # Sequence of `(nx generator, cygraph generator if available, kwargs)`.
    configurations = [
        (nx.duplication_divergence_graph, generators.duplication_divergence_graph, {"p": 0.3}),
        (nx.fast_gnp_random_graph, generators.fast_gnp_random_graph, {"p": 10 / args.num_nodes}),
        (nx.gnp_random_graph, generators.gnp_random_graph, {"p": 10 / args.num_nodes}),
    ]

    # Evaluate duration samples.
    durations_by_generator = {}
    for nxgenerator, cygenerator, kwargs in configurations:
        kwargs = kwargs | {"n": args.num_nodes}
        durations = {"networkx": evaluate_durations(nxgenerator, args.max_duration, kwargs)}
        with patch_nx_graph():
            durations["patched"] = evaluate_durations(nxgenerator, args.max_duration, kwargs)
        if cygenerator:
            durations["cygraph"] = evaluate_durations(cygenerator, args.max_duration, kwargs)
        durations_by_generator[nxgenerator.__name__] = durations

        # Report as soon as we have the results.
        mean_durations = {method: np.mean(values) for method, values in durations.items()}
        factors = {method: mean_durations["networkx"] / duration for method, duration
                   in mean_durations.items() if method != "networkx"}

        line = "; ".join(f"{method}: {factor:.3f}x" for method, factor in factors.items())
        print(f"{nxgenerator.__name__} -- {line}")

    return durations_by_generator


if __name__ == "__main__":
    __main__()
