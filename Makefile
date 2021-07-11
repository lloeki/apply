all:

lint:
	@find apply push lib -type f -not -iname '*.*' | xargs shellcheck -s bash
	@shellcheck -s dash run
	@echo -e "\033[032mOK\033[0m"
