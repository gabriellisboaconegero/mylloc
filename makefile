PROGRAM = main
LDLIBC = -dynamic-linker /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/x86_64-linux-gnu/crtn.o -lc
FILES.S = $(wildcard *.s)
FILES.C = $(wildcard *.c)
FILES = $(FILES.S:%.s=%.o)
FILES += $(FILES.C:%.c=%.o)

all: $(FILES)
	ld $^ -o $(PROGRAM) $(LDLIBC)

%.o: %.s
	as $< -o $@ -g

%.o: %.c
	gcc -c $< -o $@ -g

clean:
	rm -f *.o $(PROGRAM)

