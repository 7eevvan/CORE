from libcpp.vector cimport vector
from libcpp.set cimport set

cdef class GraphSubgraph:
    # Graph structure
    cdef int num_nodes
    cdef vector[vector[int]] adj_vector
    cdef vector[int] degree
    cdef int edges_subgraph
    
    # Node sets using vectors
    cdef vector[char] in_S 
    cdef vector[int] nodes             
    cdef vector[int] position           
    cdef int S_size                    
    
    # Algorithm info
    cdef vector[int] degree_to_S
    cdef vector[int] movement_freq
    cdef vector[int] last_moved
    cdef vector[int] tabu

    # Methods
    cdef void find_initial_solution(self, int k, int current_iteration)
    cdef void reset(self)
    cdef void add_to_S(self, int node, int current_iteration, int tabu_duration = *)
    cdef void remove_from_S(self, int node, int current_iteration, int tabu_duration = *)

    # Global node selection
    cdef int select_to_add_global(self, int current_iteration, str mode = *)
    cdef int select_to_remove_global(self, int current_iteration, int tabu_node, str mode = *)

    # Neighborhood node selection
    cdef int select_to_add_neighborhood(self, int current_iteration, str mode = *, int num_samples = *)
    cdef int select_to_remove_neighborhood(self, int current_iteration, int tabu_node, str mode = *, int num_samples = *)

    # Adding multiple nodes 
    cdef void add_region(self, vector[int] region_nodes, int current_iteration)

