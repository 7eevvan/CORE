from CORE import CORE  # type: ignore

if __name__ == "__main__":
    from load_data import read_csv_graph, read_clq_graph, remap_to_dense
    import time

    # load graph
    adj_dict = read_csv_graph('graphs/challenge.csv.gz')
    #dj_dict = read_clq_graph('graphs/brock400_2.clq')
    #adj_dict = read_clq_graph('graphs/brock800_2.clq')

    adj_dict, id_map, reverse_map = remap_to_dense(adj_dict)
    
    # run search 
    total_start_time = time.time()
    best_clique, best_time = CORE(
        adj_dict,                      # adjacency dictionary representing the graph
        gamma = 0.25,                  # density threshold for quasi-clique
        no_improve_limit = 100,        # max iterations without improvement before stopping current k-size search
        max_iterations = 1e5,          # max global iterations across all k-sizes
        region_freq = 10,              # trigger region exploration every N iterations of no improvement
        min_region_size = 10,          # minimum number of nodes to include in region
        max_region_size = 200,         # maximum number of nodes to include in region
        seed = 123,                    # random seed 
        fixed_k=369
    )
    total_time = time.time() - total_start_time

    # get solution with original ID's   
    original_clique = [reverse_map[node] for node in best_clique]

    # Print info 
    print(f"\nFound solution with {len(original_clique)} vertices in {best_time:.4f} seconds")
    print(f"Total time: {total_time:.4f} seconds")
