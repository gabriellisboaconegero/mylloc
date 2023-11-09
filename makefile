PROGRAM = main
SRCD=src
INCLUDED=include
TESTED=teste
OBJD=obj

LDLIBC = -dynamic-linker /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/x86_64-linux-gnu/crtn.o -lc
CFLAGS= -Wall -I$(INCLUDED)

FILES.S = $(wildcard $(SRCD)/*.s)
FILES.C = $(TESTED)/teste.c
FILES.S.O = $(FILES.S:$(SRCD)/%.s=$(OBJD)/%.o)
FILES.C.O = $(FILES.C:$(TESTED)/%.c=$(OBJD)/%.o)
FILES.CS.O = $(FILES.C:$(TESTED)/%.c=$(OBJD)/%.cs.o)

all: $(FILES.S.O) $(FILES.C.O)
	ld $^ -o $(PROGRAM) $(LDLIBC)

arch: LDLIBC = -dynamic-linker /lib/ld-linux-x86-64.so.2 /usr/lib/crt1.o /usr/lib/crti.o /usr/lib/crtn.o -lc
arch: all

debug_arch: LDLIBC = -dynamic-linker /lib/ld-linux-x86-64.so.2 /usr/lib/crt1.o /usr/lib/crti.o /usr/lib/crtn.o -lc
debug_arch: debug

debug: ASFLAGS = -g
debug: $(FILES.S.O) $(FILES.CS.O)
	ld $^ -o $(PROGRAM) $(LDLIBC)

$(OBJD):
	mkdir -p $(OBJD)

$(OBJD)/%.o: $(SRCD)/%.s $(INCLUDED)/%.h $(OBJD)
	as $< -o $@ $(ASFLAGS)

$(OBJD)/%.o: $(TESTED)/%.c $(OBJD)
	gcc $(CFLAGS) -c $< -o $@

$(OBJD)/%.cs.o: $(TESTED)/%.c $(OBJD)
	gcc -S $(CFLAGS) $< -o $<s
	as $<s -o $@ -g

clean:
	rm -rf $(OBJD) $(TESTED)/*.cs $(PROGRAM)

