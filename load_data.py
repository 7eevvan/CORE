import os
import gzip
import csv
import time

def read_clq_graph(file_path):
    """Read CLQ format file and return adjacency dictionary"""

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Could not find {file_path}")

    # Initialize adjacency dictionary
    adj_dict = {}
    edge_count = 0

    # Read the file and process edges
    with open(file_path, 'r') as f:
        for line in f:
            if line.startswith('e'):
                parts = line.split()
                u, v = int(parts[1]), int(parts[2])

                # Add neighbors
                if u not in adj_dict:
                    adj_dict[u] = []
                if v not in adj_dict:
                    adj_dict[v] = []

                adj_dict[u].append(v)
                adj_dict[v].append(u)
                edge_count += 1

    print(f"Created adjacency dictionary with {len(adj_dict)} nodes and {edge_count} edges")

    return adj_dict

def read_csv_graph(file_path):  
    """Read csv.gz file and return a adjacency dictionary format."""

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Could not find {file_path}")
    
    start_time = time.time()
    adj_dict = {}
    edge_count = 0

    # Read the file and process edges
    with gzip.open(file_path, 'rt') as f:
        reader = csv.reader(f)
        for edge in reader:
            if len(edge) >= 2:
                u, v = int(edge[0]), int(edge[1])

                # Add neighbors 
                if u not in adj_dict:
                    adj_dict[u] = []
                if v not in adj_dict:
                    adj_dict[v] = []

                adj_dict[u].append(v)
                adj_dict[v].append(u)
                edge_count += 1

    print(f"Created adjacency dictionary with {len(adj_dict)} nodes and {edge_count} edges in {time.time() - start_time:.2f} seconds")

    return adj_dict

def remap_to_dense(adj_dict):
    nodes = sorted(adj_dict.keys())
    id_map = {old_id: new_id for new_id, old_id in enumerate(nodes)}
    reverse_map = {new_id: old_id for old_id, new_id in id_map.items()}
    remapped = {}
    for node, neighbors in adj_dict.items():
        remapped[id_map[node]] = [id_map[neighbor] for neighbor in neighbors]
    return remapped, id_map, reverse_map