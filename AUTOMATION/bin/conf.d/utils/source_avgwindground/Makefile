#CFLAGS = -Wall -c -O3 -fimplicit-none -funroll-loops -ffloat-store -ffast-math -fopenmp -march=native
CFLAGS = -Wall -fimplicit-none -O2
#LIBS= -L/usr/lib -L/lib
CC=gfortran

Exec :
	$(CC) $(CFLAGS) avgwindground.f95 -o avgwindground $(LIBS)
	mv avgwindground ../avgwindground
