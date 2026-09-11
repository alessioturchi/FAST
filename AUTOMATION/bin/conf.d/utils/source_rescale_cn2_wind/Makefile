#CFLAGS = -Wall -c -O3 -fimplicit-none -funroll-loops -ffloat-store -ffast-math -fopenmp -march=native
CFLAGS = -Wall -c -fimplicit-none -O2
#CLEAN_ALL = mod_statistics.o mod_arrays.o mod_read_dat.o rescale_cn2_wind.o mod_statistics.mod mod_arrays.mod mod_read_dat.mod
CLEAN_ALL = *.o *.mod
#LIBS= -L/usr/lib -L/lib
CC=gfortran

Objs=	mod_statistics.o \
	mod_read_dat.o \
	rescale_cn2_wind.o \

Exec : 	clean_all link_all $(Objs)
	$(CC)   -o rescale_cn2_wind $(LIBS) $(Objs)
	mv rescale_cn2_wind ../rescale_cn2_wind
	rm mod* -f
	rm $(CLEAN_ALL) -f

link_all :
	ln -s ../modules/mod* .

clean_all :
	rm $(CLEAN_ALL) -f

mod_statistics.o : mod_statistics.f90
	$(CC) $(CFLAGS) mod_statistics.f90

mod_read_dat.o : mod_read_dat.f95
	$(CC) $(CFLAGS) mod_read_dat.f95

rescale_cn2_wind.o : rescale_cn2_wind.f95
	$(CC) $(CFLAGS) rescale_cn2_wind.f95


