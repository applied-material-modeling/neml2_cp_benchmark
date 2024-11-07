# NEML Crystal Plasticity Benchmark

This repository contains the NEML2 input files and python scripts used to benchmark the basic crystal plasticity implementation.  This is companion data to a paper submitted on the formulation.

The input files include two different crystal symmetries:
- Cubic
- Triclinic

and three different integration strategies:
- Fully coupled implicit
- Decoupled implicit (splitting the orientation from the other variables)
- Decoupled explicit (splitting the orientation from the other variables and integrating the orientations with an explicit method).

The `cubic` and `triclinic` folders contain input files for each combination of symmetry and integration stategy.

Configuring the information at the top of the `generate.py` for your system and the particular benchmark of interest will regenerate the timing data published in the paper.  Running the benchmark will also save the full results from the first and last timesteps, which were used to generate the pole figures published in the paper.

The text files committed to the repository contain the timing data published in the paper, generated on a machine with a NVIDIA RTX A5000 GPU.

The Jupyter notebooks generate the plots shown in the paper.  Running these notebooks requires first re-generating the benchmark data to make the pole figures.
