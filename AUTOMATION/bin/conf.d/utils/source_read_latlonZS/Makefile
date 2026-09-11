#CFLAGS = -Wall -c -O3 -fimplicit-none -funroll-loops -ffloat-store -ffast-math -fopenmp -march=native
CFLAGS = -Wall -c -fimplicit-none -O2 -march=native
CLEAN_ALL = *.o *.mod
#LIBS= -L/usr/lib -L/lib
CC=gfortran

Objs=	mod_read_ficval.o \
        read_latlonZS.o \

Exec : 	clean_all link_all $(Objs)
	$(CC)   -o read_latlonZS $(LIBS) $(Objs)
	mv read_latlonZS ../read_latlonZS
	rm mod* -f
	rm $(CLEAN_ALL) -f

link_all :
	ln -s ../modules/mod* .

clean_all :
	rm $(CLEAN_ALL) -f

mod_read_ficval.o : mod_read_ficval.f95
	$(CC) $(CFLAGS) mod_read_ficval.f95

read_latlonZS.o : read_latlonZS.f95
	$(CC) $(CFLAGS) read_latlonZS.f95


