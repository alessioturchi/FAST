CFLAGS = -Wall -c -fimplicit-none -O2
CLEAN_ALL = *.o *.mod
CC=gfortran

Objs=	compute_cn2_OS18.f90 \

Exec : 	clean_all $(Objs)
	$(CC) -o compute_cn2_OS18 $(Objs)
	mv compute_cn2_OS18 ../compute_cn2_OS18
	rm $(CLEAN_ALL) -f

clean_all :
	rm $(CLEAN_ALL) -f

rescale_cn2_wind.o : compute_cn2_OS18.f90
	$(CC) $(CFLAGS) compute_cn2_OS18.f90
