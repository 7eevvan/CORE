from libcpp.vector cimport vector
from libcpp.set cimport set
from libc.stdlib cimport rand, srand
from libc.time cimport time

cdef int INT_MAX = 2147483647

cdef class GraphSubgraph:
    def __init__(self, dict adj_dict):
        """Initialize graph structure from adjacency dictionary with dense node IDs [0, 1, ..., n-1]"""
        cdef int node, neighbor, max_degree, node_degree
        cdef list neighbors

        # Validate input has dense node IDs
        nodes = sorted(adj_dict.keys())
        self.num_nodes = len(nodes)
        if nodes != list(range(self.num_nodes)):
            raise ValueError(f"Node IDs must be dense [0, 1, ..., {self.num_nodes-1}]")

        # Initialize all vectors
        self.adj_vector.resize(self.num_nodes)
        self.degree.resize(self.num_nodes)
        self.in_S.resize(self.num_nodes, 0)  
        self.degree_to_S.resize(self.num_nodes, 0)
        self.movement_freq.resize(self.num_nodes, 0)
        self.last_moved.resize(self.num_nodes, 0)
        self.tabu.resize(self.num_nodes, 0)

        # set edges of subgraph
        self.edges_subgraph = 0

        # Single array approach instead of sets, where S = [0:S_size], V/S = [S_size:] 
        self.S_size = 0                        
        self.nodes.resize(self.num_nodes) 
        self.position.resize(self.num_nodes) # a node's postion in the nodes vector 
        
        # Initialize with all nodes in V\S part
        for node in range(self.num_nodes):
            self.nodes[node] = node
            self.position[node] = node

        # Fill adjacency lists and degrees
        for node, neighbors in adj_dict.items():
            self.degree[node] = len(neighbors)
            for neighbor in neighbors:
                self.adj_vector[node].push_back(neighbor)

    cdef void reset(self):
        """Reset all algorithm variables and data structures to initial state"""      
        # Reset edges count
        self.edges_subgraph = 0
        
        # Reset single array approach - all nodes back to V\S
        self.S_size = 0
        for node in range(self.num_nodes):
            self.nodes[node] = node
            self.position[node] = node 
            self.in_S[node] = 0 
            self.degree_to_S[node] = 0
            self.last_moved[node] = 0
            self.tabu[node] = 0

    cdef void find_initial_solution(self, int k, int current_iteration):
        cdef int current_S_size = 0
        cdef int selected_node
        
        while current_S_size < k:
            selected_node = self.select_to_add_global(current_iteration, "movement_frequency")
            self.add_to_S(selected_node, current_iteration)
            current_S_size += 1
        
        # Reset randomly with probabilty 0.1
        if rand() % 10 == 0:
            for node in range(self.num_nodes):
                self.movement_freq[node] = 0
                

    cdef void add_to_S(self, int node, int current_iteration, int tabu_duration = 0):
        """Add node to solution set S and update all affected neighbors and data structures"""  
        # update set vector
        cdef int node_pos = self.position[node]
        cdef int boundary_node = self.nodes[self.S_size]
        self.nodes[node_pos] = boundary_node
        self.nodes[self.S_size] = node
        self.position[boundary_node] = node_pos
        self.position[node] = self.S_size
        self.S_size += 1

        # update tracking vectors
        self.in_S[node] = 1
        self.edges_subgraph += self.degree_to_S[node]
        self.last_moved[node] = current_iteration
        self.movement_freq[node] += 1

        # set tabu 
        if tabu_duration:
            self.tabu[node] = current_iteration + rand() % tabu_duration

        # Update degree to s
        for neighbor in self.adj_vector[node]:
            self.degree_to_S[neighbor] += 1
                

    cdef void remove_from_S(self, int node, int current_iteration, int tabu_duration =0):
        """Remove node from solution set S and update all affected neighbors and data structures"""  
        # update nodes set
        cdef int node_pos = self.position[node]
        cdef int boundary_node = self.nodes[self.S_size - 1]
        self.nodes[node_pos] = boundary_node
        self.nodes[self.S_size - 1] = node
        self.position[boundary_node] = node_pos
        self.position[node] = self.S_size - 1
        self.S_size -= 1

        # Update tracking vectors
        self.in_S[node] = 0
        self.edges_subgraph -= self.degree_to_S[node]
        self.last_moved[node] = current_iteration
        self.movement_freq[node] += 1

        # Set tabu
        if tabu_duration:
            self.tabu[node] = current_iteration + rand() % tabu_duration

        # Update neighbors
        for neighbor in self.adj_vector[node]:
            self.degree_to_S[neighbor] -= 1
        

    cdef int select_to_add_global(self, int current_iteration, str mode = "recency"):
        """Select node to add based max degree_to_S, then min last_moved/movement_freq based on mode, then reservoir sample."""
        cdef int i, node, node_degree, max_degree = -1
        cdef int count = 0, selected_node = -1
        cdef int tie_break_value
        cdef int current_min_tie_break = INT_MAX
        
        # Determine which tiebreak criteria to use
        cdef vector[int]* tie_break_array
        if mode == "movement_frequency":
            tie_break_array = &self.movement_freq
        else:
            tie_break_array = &self.last_moved
        
        # Iterate only over V\S part: nodes[S_size:num_nodes]
        for i in range(self.S_size, self.num_nodes):
            node = self.nodes[i]
            node_degree = self.degree_to_S[node]
            
            # skip if not not better or tabu
            if node_degree < max_degree or self.tabu[node] > current_iteration:
                continue
                
            # Get tie-breaking value based on mode
            tie_break_value = tie_break_array[0][node]
            
            if node_degree > max_degree:  
                # Found better degree - reset everything
                max_degree = node_degree 
                current_min_tie_break = tie_break_value
                selected_node = node
                count = 1
            elif tie_break_value < current_min_tie_break:
                # Same degree, better tie-breaking value - reset
                current_min_tie_break = tie_break_value
                selected_node = node
                count = 1
            elif tie_break_value == current_min_tie_break:
                # Perfect tie - reservoir sample
                count += 1
                if rand() % count == 0:
                    selected_node = node
                    
        if selected_node == -1:
            V_min_S_index = self.S_size + rand() % (self.num_nodes - self.S_size)
            return self.nodes[V_min_S_index]
        
        return selected_node

    cdef int select_to_remove_global(self, int current_iteration, int tabu_node, str mode = "recency"):
        """Select node to remove based on min degree_to_S, then min last_moved/movement_freq based on mode, then reservoir sample."""
        cdef int i, node, node_degree, min_degree = INT_MAX
        cdef int count = 0, selected_node = -1
        cdef int tie_break_value
        cdef int current_min_tie_break = INT_MAX
        
        # Determine which tiebreak criteria to use
        cdef vector[int]* tie_break_array
        if mode == "movement_frequency":
            tie_break_array = &self.movement_freq
        else:
            tie_break_array = &self.last_moved
        
        # Iterate only over S part: nodes[0:S_size]
        for i in range(self.S_size):
            node = self.nodes[i]
            node_degree = self.degree_to_S[node]

            # skip if not not better or tabu
            if node_degree > min_degree or node == tabu_node or self.tabu[node] > current_iteration:
                continue
                
            # Get tie-breaking value based on mode
            tie_break_value = tie_break_array[0][node]
            
            if node_degree < min_degree:
                # Found better degree - reset everything
                min_degree = node_degree
                current_min_tie_break = tie_break_value
                selected_node = node
                count = 1
            elif tie_break_value < current_min_tie_break:
                # Same degree, better tie-breaking value - reset
                current_min_tie_break = tie_break_value
                selected_node = node
                count = 1
            elif tie_break_value == current_min_tie_break:
                # Perfect tie - reservoir sample
                count += 1
                if rand() % count == 0:
                    selected_node = node
                    
        if selected_node == -1:
            sampled_S_index = rand() % self.S_size
            return self.nodes[sampled_S_index]

        return selected_node

    cdef int select_to_add_neighborhood(self, int current_iteration, str mode = "recency", int num_samples=3):
        """Sample S neighbors, select based max degree_to_S, then min last_moved/movement_freq based on mode, then reservoir sample."""        
        cdef int i, sampled_S_index, sampled_node, neighbor
        cdef int max_degree = -1
        cdef int count = 0, selected_node = -1
        cdef int tie_break_value, current_min_tie_break = INT_MAX
        cdef int samples = min(num_samples, self.S_size) 
        
        # Sample nodes from S and check all their neighbors
        for i in range(samples):
            sampled_S_index = rand() % self.S_size
            sampled_node = self.nodes[sampled_S_index]
            
            # Iterate through neighbors of this sampled node
            for neighbor in self.adj_vector[sampled_node]:
                # Only consider neighbors in V\S, if better and non tabu
                if self.in_S[neighbor] or self.degree_to_S[neighbor] < max_degree or self.tabu[neighbor] > current_iteration:
                    continue
                    
                # Get tie-breaking value based on mode
                if mode == "movement_frequency":
                    tie_break_value = self.movement_freq[neighbor]
                else:  # default to "recency"
                    tie_break_value = self.last_moved[neighbor]
                    
                if self.degree_to_S[neighbor] > max_degree:
                    # Found better degree - reset everything
                    max_degree = self.degree_to_S[neighbor]
                    current_min_tie_break = tie_break_value
                    selected_node = neighbor
                    count = 1
                elif tie_break_value < current_min_tie_break:
                    # Same degree, better tie-breaking value - reset
                    current_min_tie_break = tie_break_value
                    selected_node = neighbor
                    count = 1
                elif tie_break_value == current_min_tie_break:
                    # Perfect tie - reservoir sample
                    count += 1
                    if rand() % count == 0:
                        selected_node = neighbor
        
        # Fallback if no suitable neighbor found
        if selected_node == -1:
            V_min_S_index = self.S_size + rand() % (self.num_nodes - self.S_size) 
            return self.nodes[V_min_S_index] 
        
        return selected_node


    cdef int select_to_remove_neighborhood(self, int current_iteration, int tabu_node, str mode = "recency", int num_samples=3):
        """Sample S neighbors, select based on min degree_to_S, then min last_moved/movement_freq based on mode, then reservoir sample."""        
        cdef int i, sampled_S_index, sampled_node, neighbor
        cdef int min_degree = INT_MAX
        cdef int count = 0, selected_node = -1
        cdef int tie_break_value, current_min_tie_break = INT_MAX
        cdef int samples = min(num_samples, self.S_size) 
        
        # Sample nodes from S and check their neighbors that are also in S
        for i in range(samples):
            sampled_S_index = rand() % self.S_size
            sampled_node = self.nodes[sampled_S_index]
            
            # Iterate through neighbors of this sampled node
            for neighbor in self.adj_vector[sampled_node]:
                # Only consider neighbors that are also in S, better and non tabu
                if not self.in_S[neighbor] or neighbor == tabu_node or self.degree_to_S[neighbor] > min_degree or self.tabu[neighbor] > current_iteration:
                    continue
                    
                # Get tie-breaking value based on mode
                if mode == "movement_frequency":
                    tie_break_value = self.movement_freq[neighbor]
                else:  # default to "recency"
                    tie_break_value = self.last_moved[neighbor]
                    
                if self.degree_to_S[neighbor] < min_degree:
                    # Found better (lower) degree - reset everything
                    min_degree = self.degree_to_S[neighbor]
                    current_min_tie_break = tie_break_value
                    selected_node = neighbor
                    count = 1
                elif tie_break_value < current_min_tie_break:
                    # Same degree, better tie-breaking value - reset
                    current_min_tie_break = tie_break_value
                    selected_node = neighbor
                    count = 1
                elif tie_break_value == current_min_tie_break:
                    # Perfect tie - reservoir sample
                    count += 1
                    if rand() % count == 0:
                        selected_node = neighbor
        
        # Fallback if no suitable neighbor found
        if selected_node == -1:
            sampled_S_index = rand() % self.S_size
            return self.nodes[sampled_S_index]
        
        return selected_node

    cdef void add_region(self, vector[int] region_nodes, int current_iteration):
        """Add multiple nodes to solution, then remove worst nodes to maintain original size."""
        cdef int original_size = self.S_size
        cdef int region_size = region_nodes.size() 
        cdef int node_to_remove, node_to_add
        cdef int i, nodes_added = 0

        # Phase 1: Add only region nodes that are NOT already in S
        for i in range(region_size):
            if not self.in_S[region_nodes[i]]: 
                self.add_to_S(region_nodes[i], current_iteration)
                nodes_added += 1

        # Phase 2: Remove exactly as many nodes as we added to restore original size
        for i in range(nodes_added):
            node1 = self.select_to_remove_global(current_iteration, -1)
            self.remove_from_S(node1, current_iteration)