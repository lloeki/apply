all:

lint:
	find apply run push lib -type f -not -iname '*.*' | xargs shellcheck -s bash
