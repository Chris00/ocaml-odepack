WEB = odepack.forge.ocamlcore.org:/home/groups/odepack/htdocs/

NAME = $(shell oasis query name)
DIR = $(NAME)-$(shell oasis query version)
TARBALL = $(DIR).tar.gz

DISTFILES = AUTHORS.txt INSTALL.txt README.txt \
  Makefile myocamlbuild.ml _oasis setup.ml _tags API.odocl src/META \
  $(wildcard $(addprefix src/,*.ab *.ml *.mli *.clib *.mllib *.c *.h)) \
  $(wildcard $(addprefix src/fortran/, opkda1.f opkda2.f opkdmain.f))

.PHONY: configure all byte native doc upload-doc install uninstall reinstall
all byte native: setup.data
	ocaml setup.ml -build

configure: setup.data
setup.data: setup.ml
	ocaml setup.ml -configure

setup.ml: _oasis
	oasis.dev setup

doc install: all
	ocaml setup.ml -$@
uninstall:
	ocaml setup.ml -$@
	ocamlfind remove $(NAME)
reinstall:
	$(MAKE) uninstall
	$(MAKE) install


upload-doc: doc
	scp -C -p -r _build/API.docdir $(WEB)

.PHONY: dist tar
dist tar: setup.ml
	mkdir -p $(DIR)
	for f in $(DISTFILES); do \
	  cp -r --parents $$f $(DIR); \
	done
	tar -zcvf $(TARBALL) $(DIR)
	$(RM) -r $(DIR)

.PHONY: clean distclean
clean: setup.ml
	ocaml setup.ml -clean
	$(RM) $(TARBALL) iterate.dat

distclean: setup.ml
	ocaml setup.ml -distclean
	$(RM) $(wildcard *.ba[0-9] *.bak *~ *.odocl) setup.log

odepack:
	@echo "Download odepack from http://netlib.sandia.gov/odepack/"
