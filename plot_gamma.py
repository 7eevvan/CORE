import numpy as np
import matplotlib.pyplot as plt

gammas = []
densities = []

with open("test_gamma.txt") as f:
	for line in f:
		line = line.strip()
		if line.startswith("Gamma = "):
			gammas.append(line[8:])
		if line.startswith("Density = "):
			densities.append(line[10:])

gammas = np.array(gammas)
densities = np.array(densities)

plt.plot(gammas, densities, marker="o")
plt.xlabel("Gamma")
plt.ylabel("Density")
plt.title("Density vs. Gamma")
plt.grid(True)
plt.savefig("gamma_density.png")
