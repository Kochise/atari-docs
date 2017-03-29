
OBJ =  cc68.o

c68: $(OBJ)
	cc -o c68 $(OBJ)

install: c68
	cp c68 /usr/bin/c68
	chmod 655 /usr/bin/c68

clean:
	rm -f $(OBJ) c68 core


