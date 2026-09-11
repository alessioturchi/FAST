#CFLAGS = -Wall -c -O3 -fimplicit-none -funroll-loops -ffloat-store -ffast-math -fopenmp -march=native
CFLAGS = -Wall -c -fimplicit-none -O2 -march=native 
CLEAN_ALL = *.o *.mod
#LIBS= -L/usr/lib -L/lib
CC=gfortran

Objs=	mod_read_ficval.o \
        mod_statistics.o \
        mod_cumdist.o \
        mod_statistics_wd.o \
        read_latlonWIND.o \

Exec : 	clean_all link_all $(Objs)
	$(CC)   -o read_latlonWIND $(LIBS) $(Objs)
	mv read_latlonWIND ../read_latlonWIND
	rm mod* -f
	rm $(CLEAN_ALL) -f

link_all :
	ln -s ../modules/mod* .

clean_all :
	rm $(CLEAN_ALL) -f

mod_read_ficval.o : mod_read_ficval.f95
	$(CC) $(CFLAGS) mod_read_ficval.f95

mod_statistics.o : mod_statistics.f90
	$(CC) $(CFLAGS) mod_statistics.f90

mod_cumdist.o : mod_cumdist.f90
	$(CC) $(CFLAGS) mod_cumdist.f90

mod_statistics_wd.o : mod_statistics_wd.f90
	$(CC) $(CFLAGS) mod_statistics_wd.f90

read_latlonWIND.o : read_latlonWIND.f95
	$(CC) $(CFLAGS) read_latlonWIND.f95


