#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME = decloud
PYTHON_INTERPRETER = python3
POETRY_VERSION = 1.3.2


#################################################################################
# COMMANDS                                                                      #
#################################################################################

### Setup & Dev ###
.PHONY: local-setup-dev-env install-poetry load-poetry-shell install-py-dev-reqs install-py-prod-reqs install-git-hooks install-serverless install-serverless-plugins test-watch


## Setup local development environment - install all required dependencies directly on your local machine
local-setup-dev-env: install-poetry install-py-dev-reqs install-git-hooks

## Load poetry shell
load-poetry-shell:
	poetry shell

## Install Poetry
install-poetry:
	pip3 install poetry==$(POETRY_VERSION)

## Install git pre-commit hooks
install-git-hooks:
	pre-commit install

## Install all py requirements including dev packages
install-py-dev-reqs:
	poetry install --all-extras

## Install only py packages required for production
install-py-prod-reqs:
	poetry install --only main

## Install serverless
install-serverless:
	npm install -g serverless

## Install serverless plugins
install-serverless-plugins:
	npm install serverless-plugin-aws-alerts serverless-plugin-diff

## watch relevant directories for tests and run tests when changes are detected
test-watch:
	exclude_pattern=".*"
	include_pattern=".*\.py$$"
	fswatch -or1 -e "$exclude_pattern" -i "$include_pattern" --event=Updated powr tests | xargs -n1 -I{} make test

### Current Package ###
.PHONY: install-package build-install-whl clean

## Install current package
install-package:
	poetry install --only-root

## Build Install whl
build-install-whl:
	poetry build
	pip install dist/*.whl

## Clean up cache
clean:
	find . -type f -name "*.DS_Store" -ls -delete
	find . | grep -E "(__pycache__|\.pyc|\.pyo)" | xargs rm -rf
	find . | grep -E ".pytest_cache" | xargs rm -rf
	find . | grep -E ".mypy_cache" | xargs rm -rf
	find . | grep -E ".ipynb_checkpoints" | xargs rm -rf
	find . | grep -E ".trash" | xargs rm -rf
	find . | grep -E "dist" | xargs rm -rf
	rm -f .coverage


### Testing && Linting ###
.PHONY: lint-style lint-security lint-types lint-all test test-lint-all

## Lint using flake8
lint-style:
	black .
	flake8
	isort .

## security check using bandit
lint-security:
	bandit -l --recursive -x ./tests -r .

## type checks with mypy
lint-types:
	mypy $(PROJECT_NAME)

## checks code for linting, security and type errors
lint-all: lint-style lint-types lint-security

## unit tests code with pytest
test:
	pytest -m "not smoke_dev"

## smoke test deployments with pytest
test-smoke:
	pytest -m "smoke_dev"

## runs lint-all, pytest, coverage; use when testing locally
test-lint-all: lint-all test


### Docker ###
.PHONY: docker-dev-build docker-dev-shell

## Build a docker image with local dev environment setup
docker-dev-build:
	docker build -t $(PROJECT_NAME):dev --file docker/dev.Dockerfile .

## Load a docker development shell with local dev environment setup
docker-dev-shell: docker-dev-build
	docker run -it --entrypoint /bin/bash $(PROJECT_NAME):dev


## Build a docker image with local prodph environment setup
docker-prod-build:
	docker build -t $(PROJECT_NAME):latest --file docker/prod.Dockerfile .

#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help
.PHONY: help
# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
