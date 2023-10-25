PROGRAM = main
LDLIBC = -dynamic-linker /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/x86_64-linux-gnu/crtn.o -lc
FILES.S = $(wildcard *.s)
FILES.C = $(wildcard *.c)
FILES.S.O = $(FILES.S:%.s=%.o)
FILES.C.O = $(FILES.C:%.c=%.o)
FILES.CS.O = $(FILES.C:%.c=%.cs.o)

all: $(FILES.S.O) $(FILES.C.O)
	ld $^ -o $(PROGRAM) $(LDLIBC)

arch: LDLIBC = -dynamic-linker /lib/ld-linux-x86-64.so.2 /usr/lib/crt1.o /usr/lib/crti.o /usr/lib/crtn.o -lc
arch: all

debug_arch: LDLIBC = -dynamic-linker /lib/ld-linux-x86-64.so.2 /usr/lib/crt1.o /usr/lib/crti.o /usr/lib/crtn.o -lc
debug_arch: debug

debug: ASFLAGS = -g
debug: $(FILES.S.O) $(FILES.CS.O)
	ld $^ -o $(PROGRAM) $(LDLIBC)

%.o: %.s
	as $< -o $@ $(ASFLAGS)

%.o: %.c
	gcc -c $< -o $@

%.cs.o: %.c
	gcc -S $< -o $<s
	as $<s -o $@ -g

clean:
	rm -f *.o *.cs $(PROGRAM)

