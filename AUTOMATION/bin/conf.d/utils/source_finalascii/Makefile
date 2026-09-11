#CFLAGS = -Wall -c -O3 -fimplicit-none -funroll-loops -ffloat-store -ffast-math -fopenmp -march=native
CFLAGS = -Wall -c -fimplicit-none -O2
#CLEAN_ALL = mod_read_dat.o finalascii.o mod_read_dat.mod
CLEAN_ALL = *.o *.mod
#LIBS= -L/usr/lib -L/lib
CC=gfortran

Objs=	mod_read_dat.o \
	finalascii.o \

Exec : 	clean_all link_all $(Objs)
	$(CC)   -o finalascii $(LIBS) $(Objs)
	mv finalascii ../finalascii
	rm mod* -f
	rm $(CLEAN_ALL) -f

link_all :
	ln -s ../modules/mod* .

clean_all :
	rm $(CLEAN_ALL) -f

mod_read_dat.o : mod_read_dat.f95
	$(CC) $(CFLAGS) mod_read_dat.f95

finalascii.o : finalascii.f95
	$(CC) $(CFLAGS) finalascii.f95


