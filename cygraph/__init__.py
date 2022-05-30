from .graph import Graph  # noqa: F401
try:  # pragma: no cover
    from .graph import LOGGER
    DEBUG_LOGGING = True
    del LOGGER
except ImportError:  # pragma: no cover
    DEBUG_LOGGING = False
