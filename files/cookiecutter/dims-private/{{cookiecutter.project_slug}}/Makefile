.PHONY: all
all: install-hooks

.PHONY: install-hooks
install-hooks:
	@(cd hooks; find * -type f -o -type l 2>/dev/null) | \
		while read hook; do \
			echo "[+] Installing .git/hooks/$$hook"; \
			ln -sf ../../hooks/$$hook .git/hooks/$$hook; \
		done
