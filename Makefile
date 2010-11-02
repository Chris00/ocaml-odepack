

.PHONY: all byte native install uninstall reinstall tests clean
all byte native install uninstall reinstall:
	$(MAKE) -C src $@
tests: all
	$(MAKE) -C tests all

clean:
	$(MAKE) -C src $@
	$(MAKE) -C tests $@


odepack:
	@echo "Download odepack from http://netlib.sandia.gov/odepack/"
