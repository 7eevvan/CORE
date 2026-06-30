import numpy as np
import matplotlib.pyplot as plt

gammas = []
sizes = []

best_size = 0
with open("test.txt") as f:
	for line in f:
		line = line.strip()
		if line.startswith("Gamma = "):
			gammas.append(float(line[8:]))
			if best_size != 0:
				sizes.append(best_size)
		if line.startswith("Found solution with "):
			print(line.split())
			best_size = int(line.split()[3])
sizes.append(best_size)

print(gammas, sizes)
