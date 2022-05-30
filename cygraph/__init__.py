from .graph import Graph  # noqa: F401
try:
    from .graph import LOGGER
    DEBUG_LOGGING = True
    del LOGGER
except ImportError:
    DEBUG_LOGGING = False
