SHELL=/bin/bash
.sh:
	@rm -f $@
	cp $< $@
INSTALL = mcperf onewrapper allwrapper dohosts primes

EXECDIR := $(HOME)/bin

.PHONY: uninstall all
all: $(INSTALL)
install: $(INSTALL)
	@mkdir -p $(EXECDIR)
	install -g $(USER) -o $(USER) -C $? $(EXECDIR)
	rm -f $?
clean: 
	@for execfile in $(INSTALL); do \
		echo rm -f $$execfile; \
		rm -f $$execfile; \
	done
uninstall: 
	@for execfile in $(INSTALL); do \
		echo "rm -f $(EXECDIR)/$$execfile" ; \
		rm -f $(EXECDIR)/$$execfile; \
	done
$(EXECDIR):
	mkdir -p $(EXECDIR)
