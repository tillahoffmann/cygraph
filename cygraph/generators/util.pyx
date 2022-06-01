import numbers
import os

from ..libcpp.random cimport mt19937, random_device


cdef class RandomEngine:
    """
    Mersenne Twister pseudo-random generator of 32-bit numbers with a state size of 19937 bits.

    Args:
        seed: Random number generator seed; defaults to a call to
            `random_device <https://en.cppreference.com/w/cpp/numeric/random/random_device>`_.
    """
    def __init__(self, seed: int = None):
        cdef random_device rd
        seed = os.environ.get("SEED") if seed is None else seed
        if seed is None:
            self.instance = mt19937(rd())
        else:
            self.instance = mt19937(int(seed))

    def __call__(self):
        return self.instance()


cpdef RandomEngine get_random_engine(arg=None):
    """
    Utility function to get a random engine.

    Args:
        arg: One of `None`, an integer seed, or a :class:`RandomEngine`. If `None`, a default,
            global random engine is returned. If an integer seed, a newly seeded random engine is
            returned. If a :class:`RandomEngine`, it is passed through.

    Returns:
        random_engine: Initialized :class:`RandomEngine` instance.
    """
    if arg is None:
        return DEFAULT_RANDOM_ENGINE
    elif isinstance(arg, RandomEngine):
        return arg
    elif isinstance(arg, numbers.Integral):
        return RandomEngine(arg)
    else:
        raise ValueError(arg)


DEFAULT_RANDOM_ENGINE = RandomEngine()
