ROOT = ..
include $(ROOT)/Makefile.conf
STUBS_LIB = odepack_stubs
DOCDIR = $(ROOT)/doc

INSTALL_FILES = META odepack.mli odepack.cmi odepack.cma \
	odepack.cmxa odepack.a odepack.cmx \
	$(wildcard dll$(STUBS_LIB).* lib$(STUBS_LIB).*)

FORTRAN_SRC = opkda1.f opkda2.f opkdmain.f

.PHONY: all byte native
all: byte native
byte: odepack.cma
native: odepack.cmxa

odepack.cma odepack.cmxa: $(FORTRAN_SRC:.f=$(OBJ)) odepack_stubs$(OBJ) \
  odepack.cmo odepack.cmx
	ocamlmklib -o $(basename $@) -oc $(STUBS_LIB) $^ -lgfortran

odepack_stubs$(OBJ): odepack_stubs.c
	$(OCAMLC) -c $<

opk%$(OBJ): fortran/opk%.f
	$(FORTRAN) $(FORTRAN_FLAGS) -c $<

fortran/opk%.f:
	mkdir -p fortran
	@for f in $(FORTRAN_SRC); do \
	  if [ ! -f fortran/$$f ]; then \
	    echo "Trying to get $$f"; \
	    wget http://www.netlib.org/odepack/$$f -O fortran/$$f; \
	  fi; \
	done

.PHONY: doc
doc: odepack.mli
	$(OCAMLDOC) -d $(ROOT)/doc/ -html -stars -colorize-code $^

.PHONY: install uninstall reinstall
install: META all
	$(OCAMLFIND) install $(PKG_NAME) $(INSTALL_FILES)
uninstall:
	$(OCAMLFIND) remove $(PKG_NAME)

reinstall:
	$(MAKE) uninstall
	$(MAKE) install

META: META.in odepack.mli
	sed -e "s/@PACKAGE_VERSION@/$(VERSION)/" $< > $@

include $(ROOT)/Makefile.ocaml

clean::
	$(RM) $(wildcard $(STUBS_LIB).so)