#CFLAGS = -Wall -c -O3 -fimplicit-none -funroll-loops -ffloat-store -ffast-math -fopenmp -march=native
CFLAGS = -Wall -fimplicit-none -O2 -march=native
#LIBS= -L/usr/lib -L/lib
CC=gfortran

Exec :
	$(CC) $(CFLAGS) trends_redo.f95 -o trends_redo $(LIBS)
	mv trends_redo ../trends_redo
