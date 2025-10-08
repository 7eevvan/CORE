# CORE Algorithm

I developed the **Clique Optimization with Region Exploration (CORE)** algorithm for finding maximum quasi-cliques. This algorithm finished **1st place** in the [FlyWire Max Quasi-Clique Challenge](https://codex.flywire.ai/app/max_clique_challenge). This challenge involved finding 12 quasi-cliques with different densities, with the lowest densities much sparser than what current algorithms are designed to handle. The CORE algorithm introduces an exploration mechanism called Region Exploration, which explores groups of well-connected nodes together, allowing it to discover regions where individual nodes may appear suboptimal but collectively contribute to better overall solutions.

## The Challenge

This challenge was organized by the FlyWire team at Princeton University. The task was to find dense subgraphs in the FlyWire Brain Connectome, a neuronal wiring diagram represented as an unweighted, undirected graph where vertices represent neurons and edges represent the synaptic connections of an adult female fruit fly.

![FlyWire Brain](static/flywire_brain.png)

Participants were tasked with solving the max-quasi clique problem, which is a relaxation of the classic max-clique problem. While the max-clique problem seeks the largest subgraph that is completely connected (density = 1.0), the max-quasi clique problem allows for subgraphs with a lower connectivity density of γ (gamma).

The minimum number of edges required for a quasi-clique is defined as:

**γ · [k · (k - 1) / 2]**

where `k` is the number of nodes in the subgraph and `γ` is the density threshold.

The specific goal of this challenge was to extract up to 12 large quasi-cliques, one for each density level:

**γᵢ = 1/2ⁱ, i = 0,1,...,11**

This creates density thresholds ranging from 1.0 (fully connected clique) down to approximately 0.0005 (very sparse quasi-cliques).

## The Problem with Sparse Quasi-Cliques

Current algorithms are optimized for finding dense cliques. However, when looking for sparse quasi-cliques, these algorithms might fail to find the optimal solution. This is because when searching for sparse quasi-cliques, the optimal solution can consist of multiple cores that are loosely connected together. Current algorithms struggle to discover these structures because they are either too greedy in their selection process or their exploration mechanisms fail to consider groups of nodes that collectively form better solutions.

Consider the graph shown below, which contains a fully connected core and a fully connected subcore, both represented by green nodes. The nodes in the subcore have only one connection to the larger core. Both cores have satellite nodes surrounding them, each connected to exactly three nodes in their respective cores.

![Max-Quasi-Clique Algorithm Search](static/quasi_clique_search_1.gif)

A greedy local search algorithm will successfully find one of the cores, but then becomes stuck. It only considers adding satellite nodes because they appear individually better than the green nodes of the other core. However, the green nodes together actually form the optimal solution.

Existing exploration mechanisms fail to solve this problem:

- **Restarts** don't work because when starting in either of the two cores, the algorithm will get stuck trying to greedily explore only satellite nodes which have a better individual connection to the core.
- **Tabu search** doesn't work because when many satellite nodes exist, all of them must be marked as tabu before the seemingly 'suboptimal' green nodes become visible for selection. Setting tabu duration too high will lead to bad performance, because it prevents actual bad nodes from being removed from the solution.
- **Random exploration** with tabu marking also fails. Even when a green node from the subcore is discovered by chance, the algorithm still doesn't consider other green nodes as good candidates since they have weaker connections to the current solution than other available nodes. Further random exploration needs to find a group of green nodes by chance, which becomes highly unlikely when many green nodes need to be explored together.

The key insight is that some nodes need to be explored together with their neighboring nodes to be considered viable additions to the solution.

## Clique Optimization with Region Exploration (CORE)

To solve this problem, the CORE algorithm was developed, which uses an exploration mechanism called region exploration. The algorithm uses greedy local search until no improvements can be found, then switches to region exploration or restarting the solution.

The general CORE procedure begins by generating initial solutions of a given size k and then iteratively improving them through multiple strategies. When the current solution forms a valid quasi-clique, the algorithm expands by adding a node and increasing the target size k. When no expansion is possible, the algorithm primarily uses local search through node swaps to improve solution quality, but when stuck for multiple iterations, it switches to region exploration where it adds a connected region of nodes and then removes the worst nodes to maintain solution size. This process continues until the maximum number of iterations is reached.
```python
def CORE(graph, gamma, max_iterations, max_no_improve, explore_freq):
    k = 1
    S = {}
    best_S = {}
    iterations = 0

    while iterations < max_iterations:
        S = find_initial_solution(graph, k)
        no_improve = 0

        while no_improve < max_no_improve:
            if valid_quasi_clique(S, gamma):
                k++
                S = add_node(graph, S)
            elif no_improve > 0 and no_improve % explore_freq == 0:
                S = region_exploration(graph, S)
            else:
                S = swap_node(graph, S)

            if edges(S) > edges(best_S):
                best_S = S
                no_improve = 0
            else:
                no_improve++

        iterations++

    return best_S
```
