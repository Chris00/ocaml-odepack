ROOT = ..
include $(ROOT)/Makefile.conf
OCAMLPACKS = bigarray
OCAMLINCLUDES = $(ROOT)/src

SOURCES = $(wildcard *.ml)

.PHONY: all byte native
all: byte native
native: $(SOURCES:.ml=.com)

$(SOURCES:.ml=.com) $(SOURCES:.ml=.cmx): $(ROOT)/src/odepack.cmxa
$(SOURCES:.ml=.exe) $(SOURCES:.ml=.cmo): $(ROOT)/src/odepack.cma

pendulum: pendulum.f
	$(FORTRAN) $(FORTRAN_FLAGS) -o $@ $< $(ROOT)/src/opkd*$(OBJ)

include $(ROOT)/Makefile.ocaml
