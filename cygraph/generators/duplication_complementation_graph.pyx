from ..graph cimport assert_normalized_node_labels, count_t, Graph, node_t
from ..libcpp.random cimport bernoulli_distribution, mt19937, uniform_int_distribution
from ..util import assert_interval
from .util cimport get_random_engine


IF DEBUG_LOGGING:
    import logging
    LOGGER = logging.getLogger()


def duplication_complementation_graph(n: count_t, deletion_proba: float, interaction_proba: float,
                                      graph: Graph = None, random_engine=None) -> Graph:
    r""""
    Duplication divergence graph with complementation as described by [Vazquez2003]_.

    Args:
        n: Number of nodes.
        deletion_proba: Probability that a duplicated or original edge is deleted (:math:`q` in
            [Vazquez2003]_).
        interaction_proba: Probability that the original and duplicated node are connected
            (:math:`p` in [Vazquez2003]_)
        graph: Seed graph; defaults to a pair of connected nodes.
        random_engine: See :func:`get_random_engine`.

    The growth process proceeds in four stages at each step :math:`t`:

    1. A node :math:`i` is chosen at random and duplicated to obtain a new node :math:`t`, including
       its connections.
    2. For each neighbors :math:`j`, we choose one of the edges :math:`(i, j)` and :math:`(t, j)`
       and remove it with probability `deletion_proba`. I.e., we remove at most one of the edges.
    3. The nodes :math:`i` and :math:`t` are connected with probability `interaction_proba`.
    4. Discard the new node :math:`t` if it does not have any edges. This makes it more likely but
       cannot guarantee that the graph is connected. The strategy is adpated from [Ispolatov2005]_
       who considered a simpler model without edge deletion. See :func:`duplication_mutation_graph`
       for further details.

    .. [Ispolatov2005] I. Ispolatov, P. L. Krapivsky, and A. Yuryev. Duplication-divergence model of
       protein interaction network. *Phys. Rev. E*, 71(6):061911, 2005.
       https://doi.org/10.1103/PhysRevE.71.061911
    .. [Vazquez2003] A. Vazquez, A. Flammini, A. Maritan, and A. Vespignani. Modeling of protein
       interaction networks. *Complexus*, 1(1):38--44, 2003. https://doi.org/10.1159/000067642

    .. plot::

       plot_graph(generators.duplication_complementation_graph(20, 0.6, 0.2))
    """
    # Whether to delete one of the connections.
    cdef bernoulli_distribution deletion_dist = bernoulli_distribution(deletion_proba)
    # Whether to delete the connection with the original node.
    cdef bernoulli_distribution original_dist = bernoulli_distribution(0.5)
    # Whether to create a connection between the original and new node.
    cdef bernoulli_distribution interaction_dist = bernoulli_distribution(interaction_proba)
    cdef uniform_int_distribution[node_t] random_node_dist
    cdef node_t new_node, seed_node
    cdef mt19937 random_engine_instance = get_random_engine(random_engine).instance
    assert_interval("n", n, 2, None)
    assert_interval("deletion_proba", deletion_proba, 0, 1, inclusive_high=False)
    assert_interval("interaction_proba", interaction_proba, 0, 1)
    random_engine = get_random_engine(random_engine)

    if not graph:
        graph = Graph()
        graph.add_edge(0, 1)
    assert_normalized_node_labels(graph)

    while graph.number_of_nodes() < n:
        new_node = graph.number_of_nodes()
        # Choose a random node from the current graph to duplicate. We may need to sample multiple
        # times if one of the nodes was deleted due to being disconnected. This may be costly if the
        # deletion probability is high and the interaction probability is low.
        random_node_dist = uniform_int_distribution[node_t](0, new_node - 1)
        while True:
            seed_node = random_node_dist(random_engine_instance)
            if graph.has_node(seed_node):
                break
        IF DEBUG_LOGGING:
            LOGGER.info("selected seed %d for new node %d", seed_node, new_node)

        # Duplicate edges and deal with deletion.
        for neighbor in graph._adjacency_map[seed_node]:
            if deletion_dist(random_engine_instance):  # Delete one of the edges.
                if original_dist(random_engine_instance):  # Delete the old and create the new edge.
                    graph.remove_edge(seed_node, neighbor)
                    graph.add_edge(new_node, neighbor)
                    IF DEBUG_LOGGING:
                        LOGGER.info("deleted old edge %s; created new edge %s",
                                    (seed_node, neighbor), (new_node, neighbor))
                else:  # Keep the old and don't create the new edge.
                    IF DEBUG_LOGGING:
                        LOGGER.info("did not created new edge %s", (new_node, neighbor))
            else:  # Create the new edge.
                graph.add_edge(new_node, neighbor)
                IF DEBUG_LOGGING:
                    LOGGER.info("created new edge %s", (new_node, neighbor))

        # Add interaction.
        if interaction_dist(random_engine_instance):
            graph.add_edge(seed_node, new_node)
            IF DEBUG_LOGGING:
                LOGGER.info("created complementation edge %s", (seed_node, new_node))
        else:
            IF DEBUG_LOGGING:
                LOGGER.info("did not create complementation edge %s", (seed_node, new_node))

    return graph
