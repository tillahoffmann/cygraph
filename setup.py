import os
from setuptools import find_packages, setup
from setuptools.extension import Extension
from Cython.Build import cythonize


define_macros = []
if os.environ.get('CYTHON_TRACE'):
    define_macros.append(('CYTHON_TRACE', '1'))

extensions = [
    Extension(
        name="*",
        sources=["cygraph/**/*.pyx"],
        extra_compile_args=[
            "-std=c++17",
        ],
        language="c++",
        include_dirs=[
            "include",
        ],
        define_macros=define_macros,
    ),
]

ext_modules = cythonize(
    extensions,
    annotate=True,
    compiler_directives={
        'embedsignature': True,
        'binding': True,
        'language_level': 3,
        'linetrace': True,
    },
    compile_time_env={"DEBUG_LOGGING": bool(os.environ.get("DEBUG_LOGGING"))},
)

setup(
    name="cygraph",
    packages=find_packages(),
    version="0.1.0",
    install_requires=[
    ],
    extras_require={
        "tests": [
            "cython",
            "flake8",
            "networkx",
            "pytest",
            "pytest-cov",
        ],
        "docs": [
            "matplotlib",
            "numpydoc",
            "sphinx",
        ]
    },
    ext_modules=ext_modules,
)
