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
		if line.startswith("Found clique of size "):
			best_size = int(line.split()[4])
sizes.append(best_size)


x = np.array(gammas)
y = np.array(sizes)

plt.scatter(x, y)
plt.xlabel("Gamma")
plt.ylabel("Clique Size")
plt.title("Gamma vs Clique Size")
plt.grid(True)

coeffs = np.polyfit(x, y, 2)
x_fit = np.linspace(x.min(), x.max(), 200)
y_fit = np.polyval(coeffs, x_fit)
plt.plot(x_fit, y_fit)

plt.savefig("gamma_cliquesize.png", dpi=300, bbox_inches="tight")
