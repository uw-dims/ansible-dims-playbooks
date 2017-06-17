# Makefile for DIMS Jira hooks, etc.
#

SHELL=/bin/bash
BIN=/opt/dims/bin

OWNER="dims"
GROUP="dims"
MODE="755"

INSTALL_PROGRAM=install

.PHONY: help \
	install installdirs \
	uninstall \
	installcheck

help:
	@echo "help not available (yet)"

install: installdirs \
	$(BIN)/jira-postlog \
	installcheck

$(BIN)/jira-postlog: jira-postlog
	$(INSTALL_PROGRAM) -g $(GROUP) -o $(OWNER) -m $(MODE) $< $(BIN)

uninstall:
	rm -f \
	$(BIN)/jira-postlog


installdirs:
	@if [ ! -d $(BIN) ]; then \
	   mkdir -p $(BIN); \
	   chown dims:dims $(BIN); \
	   chmod 755 $(BIN); \
	   echo "Created $(BIN) (dims:dims, mode 755)"; \
	fi

installcheck: 
	@bash test.dims-ci-utils.installcheck \
		"jira-postlog" \
		"$(BIN)" \
		"$(MODE) $(OWNER) $(GROUP)"
