# Makefile for developers.  Users can use OASIS (see INSTALL.txt).
WEB = odepack.forge.ocamlcore.org:/home/groups/odepack/htdocs/

NAME = $(shell oasis query name)
DIR = $(NAME)-$(shell oasis query version)
TARBALL = $(DIR).tar.gz

DISTFILES = AUTHORS.txt INSTALL.txt README.txt \
  Makefile myocamlbuild.ml _oasis setup.ml _tags API.odocl src/META \
  rename_c_prims.ml \
  $(wildcard $(addprefix src/,*.ab *.ml *.mli *.clib *.mllib *.c *.h)) \
  $(wildcard $(addprefix src/fortran/, $(ODEPACK))) \
  $(wildcard tests/*.ml)

.PHONY: configure all byte native doc upload-doc install uninstall reinstall
all byte native setup.log: setup.data
	ocaml setup.ml -build

configure: setup.data
setup.data: setup.ml
	ocaml setup.ml -configure

setup.ml: _oasis
	oasis setup -setup-update dynamic

doc install uninstall reinstall: setup.log
	ocaml setup.ml -$@

upload-doc: doc
	scp -C -p -r _build/API.docdir $(WEB)

.PHONY: dist tar
dist tar: setup.ml
	mkdir -p $(DIR)
	for f in $(DISTFILES); do \
	  cp -r --parents $$f $(DIR); \
	done
# Make a setup.ml independent of oasis:
	cd $(DIR) && oasis setup
	tar -zcvf $(TARBALL) $(DIR)
	$(RM) -r $(DIR)

.PHONY: clean distclean
clean: setup.ml
	ocaml setup.ml -clean
	$(RM) $(TARBALL) iterate.dat

distclean: setup.ml
	ocaml setup.ml -distclean
	$(RM) $(wildcard *.ba[0-9] *.bak *~ *.odocl)
