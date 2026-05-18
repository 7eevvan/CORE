from CORE import CORE 
from load_data import remap_to_dense
import time


def load_yeast_graph(path):
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
    # load graph
    adj_dict = load_yeast_graph('graphs/yeast.csv')

    adj_dict, id_map, reverse_map = remap_to_dense(adj_dict)

    start_time = time.time()
    best_clique, best_time = CORE(
        adj_dict,
        gamma=0.25,
        no_improve_limit=100,
        max_iterations=1e5,
        region_freq=10,
        min_region_size=10,
        max_region_size=200,
        seed=123,
        fixed_k=369
    )

    total_time = time.time() - start_time

    original_clique = [reverse_map[node] for node in best_clique]

    print(f"\nFound solution with {len(original_clique)} vertices in {best_time:.4f} seconds")
    print(f"Total time: {total_time:.4f} seconds")
