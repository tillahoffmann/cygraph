import argparse
import numpy as np
import time
from tqdm import tqdm
from .._performance_experiments import AllocationExperiment, UniqueContainerExperiment


class Timer:
    def __init__(self):
        self.start = None
        self.end = None

    def __enter__(self):
        self.start = time.time()
        return self

    def __exit__(self, *_):
        self.end = time.time()

    @property
    def duration(self):
        if self.start is None or self.end is None:
            raise ValueError("timer has not yet been used or has not finished")  # pragma: no cover
        return self.end - self.start


def __main__(args: list[str] = None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--num_repeats", type=int, default=100, help="number of repetitions to "
                        "measure execution time; script runtime scales quadratically")
    parser.add_argument("--population_size", type=int, default=1000,
                        help="number of elements to run experiments for")
    args = parser.parse_args(args)

    results = {}
    for _ in tqdm(range(args.num_repeats)):
        populations = {
            "sorted": range(args.population_size),
            "reversed": reversed(range(args.population_size)),
            "shuffled": np.random.permutation(args.population_size),
            "duplicated": np.random.randint(args.population_size // 10, size=args.population_size),
        }
        for population_key, population in populations.items():
            experiment = UniqueContainerExperiment(population)
            for method in experiment.methods:
                result_key = f"UniqueContainerExperiment.{population_key}.{method}"
                method = getattr(experiment, method)
                with Timer() as timer:
                    method(args.num_repeats)
                results.setdefault(result_key, []).append(timer.duration)

        experiment = AllocationExperiment()
        for method in experiment.methods:
            result_key = f"AllocationExperiment.{method}"
            method = getattr(experiment, method)
            with Timer() as timer:
                method(args.num_repeats)
            results.setdefault(result_key, []).append(timer.duration)

    for key, durations in results.items():
        print(f"{key}: {1e3 * np.mean(durations):.3f} ms")

    return results


if __name__ == "__main__":
    __main__()
