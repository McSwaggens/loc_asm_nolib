loc: loc.asm makefile
	nasm -felf64 loc.asm -o loc.o
	ld loc.o -o loc
	rm loc.o

run: loc
	./loc
