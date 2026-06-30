#!/bin/bash

for gamma in 0.03125 0.0625 0.125 0.25 0.5 1
do
	echo "Gamma = $gamma"
	python3 run_CORE.py graphs/yeast.csv \
	--gamma $gamma \
	--fixed_k 0 
done | tee test.txt
