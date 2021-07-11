all:

lint:
	@find apply push -type f -not -iname '*.*' | xargs shellcheck -s bash
	@find run lib -type f -not -iname '*.*' | xargs shellcheck -s dash
	@printf "\033[032mLINT OK\033[0m\n\n"

test: lint test-dash test-bash

test-ash:
	@cd test && ash ./lib_test.sh

test-dash:
	@cd test && dash ./lib_test.sh

test-bash:
	@cd test && bash ./lib_test.sh

.PHONY: lint test test-dash test-bash
