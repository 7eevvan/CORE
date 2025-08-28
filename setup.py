from setuptools import setup, Extension
from Cython.Build import cythonize

extensions = [
    Extension(
        "graph_subgraph_fast",
        ["graph_subgraph_fast.pyx"],
        language="c++",
        extra_compile_args=["-std=c++11", "-O3"],
    ),
    Extension(
        "CORE",
        ["CORE.pyx"],
        language="c++",
        extra_compile_args=["-std=c++11", "-O3"],
    ),

]

setup(
    name="graph_algorithms",
    ext_modules=cythonize(extensions, compiler_directives={
        'language_level': 3,
        'boundscheck': False,
        'wraparound': False,
        'initializedcheck': False,
        'cdivision': True,
    })
)