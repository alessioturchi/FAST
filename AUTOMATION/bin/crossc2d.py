#
# Tratto da ARMES 2D
#

SIZE=2000      # Image size
SUB=400        # Fitted subimage size
STEPS=20       # Number of steps

import numpy as np
import os,sys
import time
import resource

from scipy import optimize

def gaussian(height, center_x, center_y, width_x, width_y):
    """Returns a gaussian function with the given parameters.
       Used by the fitting procedure"""
    width_x = float(width_x)
    width_y = float(width_y)
    return lambda x,y: height*np.exp(
                -(((center_x-x)/width_x)**2+((center_y-y)/width_y)**2)/2.)


def moments(data):
    """Returns (height, x, y, width_x, width_y)
    the gaussian parameters of a 2D distribution by calculating its moments.
    It is used by the fitting procedure to extimate initial values """
    total = data.sum()
    X, Y = np.indices(data.shape)
    x = (X*data).sum()/total
    y = (Y*data).sum()/total
    col = data[:, int(y)]
    width_x = np.sqrt(np.abs((np.arange(col.size)-y)**2*col).sum()/col.sum())
    row = data[int(x), :]
    width_y = np.sqrt(np.abs((np.arange(row.size)-x)**2*row).sum()/row.sum())
    height = data.max()
    return height, x, y, width_x, width_y

def fitgaussian(data):
    """Returns (height, x, y, width_x, width_y)
    the gaussian parameters of a 2D distribution found by a fit"""
    params = moments(data)
    errorfunction = lambda p: np.ravel(gaussian(*p)(*np.indices(data.shape)) - data)
    p, success = optimize.leastsq(errorfunction, params)
    return p

def gaussian2d(size,offset=0,width=10):
  '''Returns an array with gaussian data.
        size: size of square array, or (sx,sy)
        offset=center offset, or (ofx,ofy)
        width=circular width, or (wx,wy)'''
  if isinstance(size,(tuple,list)):
    sizex,sizey=int(size[0]),int(size[1])
  else:
    sizex=sizey=int(size)
  if isinstance(offset,(tuple,list)):
    ofstx,ofsty=float(offset[0]),float(offset[1])
  else:
    ofstx=ofsty=float(offset)
  if isinstance(width,(tuple,list)):
    widthx,widthy=float(width[0]),float(width[1])
  else:
    widthx=widthy=float(width)
  center=float(size)*0.5
  center_x=center+ofstx
  center_y=center+ofsty

  x=np.arange(sizex,dtype=np.float32)
  y=np.arange(sizey,dtype=np.float32).reshape((-1,1))

#  return np.exp(-4*np.log(2)*(((x-center_x)/widthx)**2 +((y-center_y)/widthy)**2))
  return np.exp(-0.5*(((x-center_x)/widthx)**2 +((y-center_y)/widthy)**2))


def crosscorrfft(l,r):
  """
Computes the cross correlation using FFT/iFFT.
"""
  lf=np.fft.fft2(l)
  rf=np.fft.fft2(r)
  lf=np.conj(lf)
  iff=np.absolute(np.fft.ifft2(lf*rf))
  return np.fft.fftshift(iff)          # fftshift moves zero to center pixels

def findmax_gauss(data):
  '''
Finds the maximum of a curve.

Method: evaluates the fitting gaussian

Returns: h, x, y, wx, wy 
'''

  return fitgaussian(data)



def onestep(i1,i2,func):
 
  '''This procedure 

     1. Compute the cross correlation with given method
     2. Fits a gaussian on the central part of the cross correlation matrix
'''

  cc=func(i1,i2)                 # calcola crosscorrelazione

  s0,d=cc.shape
  s0=float(s0)*0.5
  x0=int(s0-SUB)
  x1=int(s0+SUB)

  c0=cc[x0:x1,x0:x1]                     # Estrae parte centrale
  h, x, y, wx, wy = findmax_gauss(c0)
                                         # Aggiusta coordinate
  csx=float(SUB)-y
  csy=float(SUB)-x
  return csx,csy


def dothejob(sx,sy):
 
  '''This procedure performs the full simulation:

     1. Generates two gaussian images 
     2. Compute the cross correlation (with FFT based method)
     2. Fits a gaussian on the central part of the cross correlation matrix
'''

  i1=gaussian2d(SIZE,(-sx*0.5,-sy*0.5),width=5)         # Generate a gaussian
  i2=gaussian2d(SIZE,(sx*0.5,sy*0.5),width=5)           # Generate a gaussian

  csx,csy=onestep(i1,i2,crosscorrfft)

t0 = time.time()
verbose=False
if '-v' in sys.argv: verbose=True

steps=STEPS
if '-f' in sys.argv: steps=1
for i in xrange(steps):
  sx=np.random.random_sample()*10.0-5.0
  sy=np.random.random_sample()*10.0-5.0
  dothejob(sx,sy)
r=resource.getrusage(resource.RUSAGE_SELF)
t1 = time.time()

elaps=(t1-t0)
perc=(r.ru_utime+r.ru_stime)/elaps*100
perc=min(perc,100.0)

if verbose:
  print 'Size:    (%d/%d)' % (SIZE,steps)
  print 'Elapsed: %f' % elaps
  print 'User:    %f' % r.ru_utime
  print 'System:  %f' % r.ru_stime
  print 'MaxMem:  %d' % r.ru_maxrss
  print 'CPU us:  %.1f%%' % perc
  print 'Faults:  %d' % r.ru_majflt
  print 'Swaps:   %d' % r.ru_nswap

else:
  print '(%d/%d),%f,%f,%f,%.1f%%,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d' % (SIZE,steps,elaps,r.ru_utime,r.ru_stime,perc,r.ru_maxrss, r.ru_ixrss, r.ru_idrss, r.ru_isrss, r.ru_minflt, r.ru_majflt, r.ru_nswap, r.ru_inblock, r.ru_oublock, r.ru_msgsnd, r.ru_msgrcv, r.ru_nsignals, r.ru_nvcsw,r.ru_nivcsw)


sys.stdout.flush()
