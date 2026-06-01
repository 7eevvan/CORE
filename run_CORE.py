from CORE import CORE 
from load_data import remap_to_dense
import time
import argparse

def load_graph(path):
    adj = {}
    with open(path) as f:
        for line in f:
            if not line.strip():
                continue
            u, v = line.strip().split(';')
            adj.setdefault(u, set()).add(v)
            adj.setdefault(v, set()).add(u)
    return adj


if __name__ == "__main__":
	parser = argparse.ArgumentParser(description="Run CORE on a graph")
	parser.add_argument("graph", help="Path to graph file")
	parser.add_argument("--gamma", type=float, default=0.25)
	parser.add_argument("--no_improve_limit", type=int, default=100)
	parser.add_argument("--max_iterations", type=float, default=1e5)
	parser.add_argument("--region_freq", type=int, default=10)
	parser.add_argument("--min_region_size", type=int, default=10)
	parser.add_argument("--max_region_size", type=int, default=200)
	parser.add_argument("--seed", type=int, default=123)
	parser.add_argument("--fixed_k", type=int, default=36)
	args = parser.parse_args()

    # load graph
	adj_dict = load_graph(args.graph)
	adj_dict, id_map, reverse_map = remap_to_dense(adj_dict)
	start_time = time.time()
	best_clique, best_time = CORE(
		adj_dict,
        gamma=args.gamma,
       	no_improve_limit=args.no_improve_limit,
        max_iterations=args.max_iterations,
        region_freq=args.region_freq,
        min_region_size=args.min_region_size,
        max_region_size=args.max_region_size,
        seed=args.seed,
        fixed_k=args.fixed_k
    )

	total_time = time.time() - start_time

	original_clique = [reverse_map[node] for node in best_clique]

	print(original_clique)
	print(f"\nFound solution with {len(original_clique)} vertices in {best_time:.4f} seconds")
	print(f"Total time: {total_time:.4f} seconds")

	# test gammas
	res = []
	gammas = [0.0625, 0.125, 0.25, 0.5, 1]
	for gamma in gammas:
		print("Running gamma: " + str(gamma))
		
		start_time = time.time()
		best_clique, best_time = CORE(
			adj_dict,
			gamma=gamma,
			no_improve_limit=args.no_improve_limit,
        	max_iterations=args.max_iterations,
        	region_freq=args.region_freq,
        	min_region_size=args.min_region_size,
        	max_region_size=args.max_region_size,
        	seed=args.seed,
        	fixed_k=args.fixed_k
    	)
		total_time = time.time() - start_time

		# compute density of the solution
		solution_set = set(best_clique)
		edge_count = 0
		for u in best_clique:
			for v in adj_dict[u]:
				if v in solution_set:
					edge_count += 1
		edge_count //= 2

		k = len(best_clique)
		possible_edges = k * (k-1) / 2
		density = edge_count / possible_edges if possible_edges else 0
		print(density)

		

		

