

.PHONY: all byte native install uninstall reinstall doc tests clean
all byte native install uninstall reinstall doc:
	$(MAKE) -C src $@
tests: all
	$(MAKE) -C tests all

clean:
	$(MAKE) -C src $@
	$(MAKE) -C tests $@
	$(MAKE) -C doc $@


odepack:
	@echo "Download odepack from http://netlib.sandia.gov/odepack/"
