#CFLAGS = -Wall -c -O3 -fimplicit-none -funroll-loops -ffloat-store -ffast-math -fopenmp -march=native
CFLAGS = -Wall -c -fimplicit-none -O2
#CLEAN_ALL = mod_statistics.o mod_arrays.o mod_read_dat.o treat_seeisotau_evol.o mod_statistics.mod mod_arrays.mod mod_read_dat.mod
CLEAN_ALL = *.o *.mod
#LIBS= -L/usr/lib -L/lib
CC=gfortran

Objs=	mod_statistics.o \
	mod_arrays.o \
	mod_read_dat.o \
	treat_seeisotau_evol.o \

Exec : 	clean_all link_all $(Objs)
	$(CC)   -o treat_seeisotau_evol $(LIBS) $(Objs)
	mv treat_seeisotau_evol ../treat_seeisotau_evol
	rm mod* -f
	rm $(CLEAN_ALL) -f

link_all :
	ln -s ../modules/mod* .

clean_all :
	rm $(CLEAN_ALL) -f

mod_statistics.o : mod_statistics.f90
	$(CC) $(CFLAGS) mod_statistics.f90

mod_arrays.o : mod_arrays.f90
	$(CC) $(CFLAGS) mod_arrays.f90

mod_read_dat.o : mod_read_dat.f95
	$(CC) $(CFLAGS) mod_read_dat.f95

treat_seeisotau_evol.o : treat_seeisotau_evol.F95
	$(CC) $(CFLAGS) treat_seeisotau_evol.F95


