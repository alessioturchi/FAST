#CFLAGS = -Wall -c -O3 -fimplicit-none -funroll-loops -ffloat-store -ffast-math -fopenmp -march=native
CFLAGS = -Wall -c -fimplicit-none -O2 -march=native
#CLEAN_ALL = mod_read_dat.o mod_statistics.o mod_statistics_wd.o mod_arrays.o mod_arrays_wd.o treat_wind_evollevel.o mod_read_dat.mod mod_statistics.mod mod_statistics_wd.mod mod_arrays.mod mod_arrays_wd.mod
CLEAN_ALL = *.o *.mod
#LIBS= -L/usr/lib -L/lib
CC=gfortran

Objs=	mod_read_dat.o \
	mod_statistics.o \
	mod_statistics_wd.o \
	mod_arrays_wd.o \
	mod_arrays.o \
	treat_wind_evollevel.o \

Exec : 	clean_all link_all $(Objs)
	$(CC)   -o treat_wind_evollevel $(LIBS) $(Objs)
	mv treat_wind_evollevel ../treat_wind_evollevel
	rm mod* -f
	rm $(CLEAN_ALL) -f

link_all :
	ln -s ../modules/mod* .

clean_all :
	rm $(CLEAN_ALL) -f

mod_read_dat.o : mod_read_dat.f95
	$(CC) $(CFLAGS) mod_read_dat.f95

mod_statistics.o : mod_statistics.f90
	$(CC) $(CFLAGS) mod_statistics.f90

mod_statistics_wd.o : mod_statistics_wd.f90
	$(CC) $(CFLAGS) mod_statistics_wd.f90

mod_arrays.o : mod_arrays.f90
	$(CC) $(CFLAGS) mod_arrays.f90

mod_arrays_wd.o : mod_arrays_wd.f90
	$(CC) $(CFLAGS) mod_arrays_wd.f90

treat_wind_evollevel.o : treat_wind_evollevel.f95
	$(CC) $(CFLAGS) treat_wind_evollevel.f95


