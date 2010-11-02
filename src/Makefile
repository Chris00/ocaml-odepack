ROOT = ..
include $(ROOT)/Makefile.conf
STUBS_LIB = odepack_stubs
DOCDIR = $(ROOT)/doc

INSTALL_FILES = META odepack.mli odepack.cmi odepack.cma \
	odepack.cmxa odepack.a odepack.cmx \
	$(wildcard dll$(STUBS_LIB).* lib$(STUBS_LIB).*)

.PHONY: all byte native
all: byte native
byte: odepack.cma
native: odepack.cmxa

odepack.cma odepack.cmxa: odepack.cmo odepack.cmx \
  opkda1$(OBJ) opkda2$(OBJ) opkdmain$(OBJ) odepack_stubs$(OBJ)
	ocamlmklib -o $(basename $@) -oc $(STUBS_LIB) $^ $(FILIB_LIB) \
	-lgfortran

odepack_stubs$(OBJ): odepack_stubs.c
	$(OCAMLC) -c $<

opk%$(OBJ): fortran/opk%.f
	$(FORTRAN) $(FORTRAN_FLAGS) -c $<

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
	$(RM) $(wildcard dllodepack_stubs.so)