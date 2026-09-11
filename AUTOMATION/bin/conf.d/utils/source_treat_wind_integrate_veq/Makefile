#CFLAGS = -Wall -c -O3 -fimplicit-none -funroll-loops -ffloat-store -ffast-math -fopenmp -march=native
CFLAGS = -Wall -c -fimplicit-none -O2 -march=native
#CLEAN_ALL = mod_statistics.o mod_statistics_wd.o mod_arrays.o mod_read_dat.o treat_wind_integrate_veq.o mod_statistics.mod mod_statistics_wd.mod mod_arrays.mod mod_read_dat.mod
CLEAN_ALL = *.o *.mod
#LIBS= -L/usr/lib -L/lib
CC=gfortran

Objs=	mod_statistics.o \
	mod_statistics_wd.o \
	mod_arrays.o \
	mod_read_dat.o \
	treat_wind_integrate_veq.o \

Exec : 	clean_all link_all $(Objs)
	$(CC)   -o treat_wind_integrate_veq $(LIBS) $(Objs)
	mv treat_wind_integrate_veq ../treat_wind_integrate_veq
	rm mod* -f
	rm $(CLEAN_ALL) -f

link_all :
	ln -s ../modules/mod* .

clean_all :
	rm $(CLEAN_ALL) -f

mod_statistics.o : mod_statistics.f90
	$(CC) $(CFLAGS) mod_statistics.f90

mod_statistics_wd.o : mod_statistics_wd.f90
	$(CC) $(CFLAGS) mod_statistics_wd.f90

mod_arrays.o : mod_arrays.f90
	$(CC) $(CFLAGS) mod_arrays.f90

mod_read_dat.o : mod_read_dat.f95
	$(CC) $(CFLAGS) mod_read_dat.f95

treat_wind_integrate_veq.o : treat_wind_integrate_veq.f95
	$(CC) $(CFLAGS) treat_wind_integrate_veq.f95


