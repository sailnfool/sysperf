SHELL=/bin/bash
PREFIX?=$(HOME)
LPREFIX?=$(HOME)/.local
SPREFIX?=/usr/local
PREFIX2?=/tftpboot/global/rnovak
.sh:
	@rm -f $@
	cp $< $@
LINSTALL =       func.errecho \
		func.insufficient \
		func.kbytes \
		func.nice2num \
		func.os \
		func.regex \
		func.toseconds \

EXECDIR := $(PREFIX)/bin
LEXECDIR := $(LPREFIX)/bin
EXECDIR2 := $(PREFIX2)/bin
SEXECDIR := $(SPREFIX)/sbin


.PHONY: clean uninstall all
all: $(LINSTALL)
linstall: $(LINSTALL)
	mkdir -p $(LEXECDIR)
	install -o $(USER) -C $? $(LEXECDIR)
	rm -f $?
#install: $(INSTALL)
#	mkdir -p $(EXECDIR)
#	install -o $(USER) -C $? $(EXECDIR)
#	rm -f $?
#sinstall: $(INSTALL)
#	mkdir -p $(SEXECDIR)
#	install -o root -C $? $(SEXECDIR)
check: $(LINSTALL)
	set -x ; for execfile in $(LINSTALL); do \
		if [[ ! $$(diff $$execfile $(LEXECDIR) ) ]] ;\
		then \
			echo "$$execfile is out of date" ; \
		fi ;\
		done
	
clean: 
	@for execfile in $(INSTALL); do \
		echo rm -f $$execfile; \
		rm -f $$execfile; \
	done
uninstall: 
	@for execfile in $(INSTALL); do \
		echo rm -f $(EXECDIR)/$$execfile; \
		rm -f $(EXECDIR)/$$execfile; \
	done
suninstall: 
	@for execfile in $(INSTALL); do \
		echo rm -f $(SEXECDIR)/$$execfile; \
		rm -f $(SEXECDIR)/$$execfile; \
	done
jetinstall: $(INSTALL)
	mkdir -p $(EXECDIR2)
	install -o $(USER) -c $? $(EXECDIR2)
$(EXECDIR):
	mkdir -p $(EXECDIR)
$(SEXECDIR):
	mkdir -p $(SEXECDIR)
$(EXECDIR2):
	mkdir -p $(EXECDIR2)
