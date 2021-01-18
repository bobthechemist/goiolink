SHELL=/bin/bash # for access to shell expansion
CC = gcc
# Setting Wolfram directories
MVER = 12.1
MLINKDIR = /opt/Wolfram/WolframEngine/$(MVER)/SystemFiles/Links/MathLink/DeveloperKit
CADDSDIR = $(MLINKDIR)/Linux-ARM/CompilerAdditions
LIBDIR = $(CADDSDIR)
MPREP = $(CADDSDIR)/mprep
# Flags
CFLAGS = -I/usr/include/GoIO -I$(CADDSDIR) -Wl,--no-as-needed -ldl
LIBS = -lGoIO -lm -luuid -lML32i4
# Assume all .h files are dependencies
DEPS = $(shell ls *.h)
__OBJ = $(shell ls *.{c,tm})
_OBJ = $(__OBJ:.c=.o)
OBJ = $(_OBJ:.tm=tm.o)

goio: $(OBJ)
	$(CC) $(CFLAGS) $^ -L$(LIBDIR) $(LIBS) -o $@

$(ODIR)/%.o: %.c $(DEPs)
	$(CC) -c -o $@ $< $(CFLAGS)

%tm.c : %.tm
	$(MPREP) $? -o $@

.PHONY: clean

clean:
	rm -f *.o
# For testing purposes, type `make print-VAR` to get the value of VAR
print-%: ; @echo $* = $($*)
