from graph_subgraph cimport GraphSubgraph
from libcpp.vector cimport vector
from libc.stdlib cimport rand, srand
from libc.math cimport ceil
from time import time

cdef vector[int] region_exploration(GraphSubgraph region_graph, GraphSubgraph main_graph, int target_region_size):
    """Find a region of nodes by selectiong a random node that is not in S, then using neighborhood expansion"""
    cdef int i
    cdef int current_iteration = 0
    
    # Reset the region graph
    region_graph.reset()
    
    # Set current solution nodes tabu in region graph
    for i in range(main_graph.S_size):
        region_graph.tabu[main_graph.nodes[i]] = int(1e9)
    
    # Create region by random sampling first node, then adding best neighbors
    cdef int current_S_size = 0
    cdef int selected_node
        
    while current_S_size < target_region_size:
        if current_S_size == 0:
            V_min_S_index = main_graph.S_size + rand() % (main_graph.num_nodes - main_graph.S_size)
            selected_node = main_graph.nodes[V_min_S_index]
        else:
            selected_node = region_graph.select_to_add_neighborhood(current_iteration, "movement_frequency")
        region_graph.add_to_S(selected_node, current_iteration)
        current_S_size += 1
    
    # Extract solution from graph
    cdef vector[int] result
    result.resize(region_graph.S_size)
    for i in range(region_graph.S_size):
        result[i] = region_graph.nodes[i]
    
    return result


cpdef tuple CORE(dict adj_dict, double gamma, int no_improve_limit, int max_iterations, int region_freq, int min_region_size, int max_region_size, int seed):
    """Find maximum quasi-clique using local search with region based exploration."""
    cdef list best_solution = []
    cdef int global_iter = 0
    cdef int k = 1
    cdef int no_improve_iter
    cdef int node_to_add, node_to_remove
    cdef int required_edges
    cdef int best_edges_for_k
    cdef GraphSubgraph graph
    cdef GraphSubgraph region_graph 
    cdef vector[int] selected_region
    cdef int target_region_size
    cdef int i
    cdef double start_time, best_time

    # set random seed
    srand(seed)

    # initialize Graph Subgraph
    graph = GraphSubgraph(adj_dict)
    region_graph = GraphSubgraph(adj_dict)

    # initialze required edges
    required_edges = <int>ceil(gamma * k * (k - 1) / 2 - 1e-9)

    # start time
    start_time = time()
    best_time = start_time
    
    # main CORE algorithm loop
    while global_iter < max_iterations:
        # Reset graph
        graph.reset()

        # Find initial solution
        graph.find_initial_solution(k, global_iter)
        
        # Fill candidates after initial solution        
        no_improve_iter = 0
        best_edges_for_k = graph.edges_subgraph
        
        while no_improve_iter < no_improve_limit and global_iter < max_iterations:
        
            # check for valid quasi clique and expand
            if graph.edges_subgraph >= required_edges:
                best_time = time()
                print(f"Found clique of size {k} with {graph.edges_subgraph} edges, Iteration: {global_iter}, Time: {best_time - start_time:.4f}s", end="\r")
                
                # Clear previous solution and collect new one
                #best_solution.clear()
                #for i in range(graph.S_size):
                #    best_solution.append(graph.nodes[i])
                
                k += 1
                required_edges = <int>ceil(gamma * k * (k - 1) / 2 - 1e-9)
                node_to_add = graph.select_to_add_global(global_iter)
                graph.add_to_S(node_to_add, global_iter)

            # Core injection logic
            elif no_improve_iter % region_freq == 0 and no_improve_iter > 0:
                # Create and add region 
                target_region_size = rand() % (max_region_size - min_region_size + 1) + min_region_size
                selected_region = region_exploration(region_graph, graph, target_region_size)
                graph.add_region(selected_region, global_iter)
            else: 
                # Add node to solution
                node_to_add = graph.select_to_add_global(global_iter)
                graph.add_to_S(node_to_add, global_iter)

                # Remove node to solution
                node_to_remove = graph.select_to_remove_global(global_iter, node_to_add)
                graph.remove_from_S(node_to_remove, global_iter)

            # check if number of edges improved, update iteration counts
            if graph.edges_subgraph > best_edges_for_k:
                best_edges_for_k = graph.edges_subgraph
                no_improve_iter = 0
            else:
                no_improve_iter += 1
            
            global_iter += 1
    
    return best_solution, best_time - start_time