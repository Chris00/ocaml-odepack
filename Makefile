# Makefile for developers.  Users can use OASIS (see INSTALL.txt).
ODEPACK_URL = http://netlib.sandia.gov/odepack/
ODEPACK_FILES = opkda1.f opkda2.f opkdmain.f
ODEPACK_DIR = src/fortran
WEB = odepack.forge.ocamlcore.org:/home/groups/odepack/htdocs/

CURL = curl --insecure --retry 2 --retry-delay 2 --location --remote-name
NAME = $(shell oasis query name)
DIR = $(NAME)-$(shell oasis query version)
TARBALL = $(DIR).tar.gz

DISTFILES = INSTALL.txt Makefile myocamlbuild.ml _oasis _opam setup.ml _tags \
  $(wildcard $(addprefix src/,*.ab *.ml *.mli *.clib *.mllib *.c *.h)) \
  $(wildcard src/fortran/*) $(wildcard tests/*.ml)

.PHONY: configure all byte native doc upload-doc install uninstall reinstall
all byte native setup.log: setup.data opam/opam
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

# Get odepack FORTRAN codes
odepack:
	mkdir -p $(ODEPACK_DIR)
	cd $(ODEPACK_DIR) && \
	for f in $(ODEPACK_FILES); do \
	  $(CURL) $(addprefix $(ODEPACK_URL), $$f); \
	done
	ocaml rename_c_prims.ml

opam/opam: _oasis
	oasis2opam --local -y

clean: setup.ml
	ocaml setup.ml -clean
	$(RM) $(TARBALL) iterate.dat

distclean: setup.ml
	ocaml setup.ml -distclean
	$(RM) $(wildcard *.ba[0-9] *.bak *~ *.odocl)

.PHONY: odepack clean distclean
