# Makefile for Jenkins notification hook, DSLs, job scripts
# DSL scripts have to be in DSL directory with name jenkins*.groovy
# Other Jenkins scripts should be in job-scripts directory with
# name jenkins.*

SHELL=/bin/bash
BIN=/opt/dims/bin

OWNER="dims"
GROUP="dims"
MODE="755"

INSTALL_PROGRAM=install

CWD=$(shell pwd)
JOBDIRECTORY=job-scripts
DSLDIRECTORY=DSL
# Get array of all scripts in job-scripts directory
JENKINSPATHS=$(wildcard $(CWD)/$(JOBDIRECTORY)/jenkins.*)
JENKINSTARGETS=$(subst $(CWD)/$(JOBDIRECTORY),$(BIN),$(JENKINSPATHS))
# Get array of all DSL scripts in DSL directorty
DSLPATHS=$(wildcard $(CWD)/$(DSLDIRECTORY)/*.groovy)
DSLTARGETS=$(subst $(CWD)/$(DSLDIRECTORY),$(BIN),$(DSLPATHS))

.PHONY: help \
	install installdirs \
	uninstall \
	installcheck

help:
	@echo "help not available (yet)"

install: installdirs \
	uninstall \
	$(JENKINSTARGETS) \
	$(DSLTARGETS) \
	$(BIN)/jenkins.artifactsrsync \
	$(BIN)/jenkins-postlog


installdirs:
	@if [ ! -d $(BIN) ]; then \
	   mkdir -p $(BIN); \
	   chown dims:dims $(BIN); \
	   chmod 755 $(BIN); \
	   echo "Created $(BIN) (dims:dims, mode 755)"; \
	fi

$(BIN)/jenkins.artifactsrsync: jenkins.artifactsrsync
	$(INSTALL_PROGRAM) -g $(GROUP) -o $(OWNER) -m $(MODE) $< $(BIN)

$(BIN)/jenkins-postlog: jenkins-postlog
	$(INSTALL_PROGRAM) -g $(GROUP) -o $(OWNER) -m $(MODE) $< $(BIN)

$(DSLTARGETS): $(BIN)/% : $(DSLDIRECTORY)/%
	$(INSTALL_PROGRAM) -g $(GROUP) -o $(OWNER) -m $(MODE) $< $(BIN)

$(JENKINSTARGETS): $(BIN)/% : $(JOBDIRECTORY)/%
	$(INSTALL_PROGRAM) -g $(GROUP) -o $(OWNER) -m $(MODE) $< $(BIN)


uninstall:
	rm -f \
	$(BIN)/jenkins-postlog \
	$(BIN)/jenkins*.groovy \
	$(BIN)/jenkins.* 
