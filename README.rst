cygraph
=======

.. image:: https://github.com/tillahoffmann/cygraph/actions/workflows/main.yml/badge.svg
   :target: https://github.com/tillahoffmann/cygraph/actions/workflows/main.yml
.. image:: https://readthedocs.org/projects/cygraph/badge/?version=latest
   :target: https://cygraph.readthedocs.io/en/latest/?badge=latest

Cygraph offers a high-performance drop-in replacement for unattributed, unweighted, undirected `networkx <https://github.com/networkx/networkx>`_ graphs. Using :code:`cygraph.Graph` instead of :code:`networkx.Graph` typically speeds up your code a little. Using :code:`cygraph`'s `cython <https://github.com/cython/cython>`_ interface enables order-of-magnitude performance improvements.

Installation
------------

The most recent version of cygraph can be installed by running :code:`pip install https://github.com/tillahoffmann/cygraph/tarball/master`. Replace :code:`master` with a particular commit or `tag <https://github.com/tillahoffmann/cygraph/tags>`_ to install a specific version. If you want to further develop cygraph, you can install the package in editable mode by cloning the repository and running :code:`pip install -e .` from the root directory (make sure to rerun the command after changing :code:`.pyx` or :code:`.pxd` files). Cygraph is not currently released on `PyPI <https://pypi.org>`_ because of a naming conflict.

.. toctree::
   :hidden:

   docs/generators
   docs/graph
   docs/util
