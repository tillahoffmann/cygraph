.PHONY : docs doctests lint sync tests

build : lint tests docs doctests

lint :
	flake8

tests :
	pytest -v --cov=cygraph --cov-fail-under=100 --cov-report=term-missing --cov-report=html

docs :
	rm -rf docs/_build
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

CURRENT_BRANCH = $(shell git branch --show-current)

workspace/profile : workspace/profile-${CURRENT_BRANCH}.prof workspace/profile-${CURRENT_BRANCH}.txt

workspace/profile-${CURRENT_BRANCH}.prof workspace/profile-${CURRENT_BRANCH}.txt : cygraph/scripts/profile.py
	mkdir -p $(dir $@)
	python -m cProfile -o workspace/profile-${CURRENT_BRANCH}.prof -m cygraph.scripts.profile \
		--max_duration=3 1000 > workspace/profile-${CURRENT_BRANCH}.txt

workspace/performance_experiments-${CURRENT_BRANCH}.txt :
	mkdir -p $(dir $@)
	python -m cygraph.scripts.performance_experiments --num_repeats=250 > $@
