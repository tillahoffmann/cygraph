.PHONY : docs doctests lint sync tests

build : lint tests docs doctests

lint :
	flake8

tests :
	pytest -v --cov=cygraph --cov-fail-under=100 --cov-report=term-missing --cov-report=html

docs :
	sphinx-build . docs/_build

doctests :
	sphinx-build -b doctest . docs/_build

sync : requirements.txt
	pip-sync

requirements.txt : requirements.in setup.py test_requirements.txt
	pip-compile -v -o $@ $<

test_requirements.txt : test_requirements.in setup.py
	pip-compile -v -o $@ $<

import_tests :
	cd tests && cythonize -af3 test.pyx

clean :
	rm -f cygraph/*.cpp cygraph/*.html cygraph/*.so
