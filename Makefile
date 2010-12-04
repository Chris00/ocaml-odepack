ROOT = .
include Makefile.conf

.PHONY: all byte native install uninstall reinstall doc upload-doc tests clean
all byte native install uninstall reinstall doc upload-doc:
	$(MAKE) -C src $@
tests: all
	$(MAKE) -C tests all

clean:
	$(MAKE) -C src $@
	$(MAKE) -C tests $@
	$(MAKE) -C doc $@

.PHONY: dist tar
dist tar:
	bzr export /tmp/$(TARBALL) -r "tag:$(VERSION)"
	@echo "Created tarball '/tmp/$(TARBALL)'."

odepack:
	@echo "Download odepack from http://netlib.sandia.gov/odepack/"
