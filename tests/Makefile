ROOT = ..
include $(ROOT)/Makefile.conf
OCAMLPACKS = bigarray
OCAMLINCLUDES = $(ROOT)/src

SOURCES = $(wildcard *.ml)

.PHONY: all byte native
all: byte native
native: $(SOURCES:.ml=.com)

$(SOURCES:.ml=.com): $(ROOT)/src/odepack.cmxa
$(SOURCES:.ml=.exe): $(ROOT)/src/odepack.cma

include $(ROOT)/Makefile.ocaml
