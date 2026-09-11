#
# Spawn many crossc2d processes to benchmarks multiprocessing performances.

import sys,os
import subprocess as sub
import time
import scipy
import numpy
import re

myVersion='1.4'

PYTHON = '/usr/bin/python'
PROCEDURE = 'crossc2d.py'
UPTIME = 'uptime'

def multi(howmany):
  global out
  if howmany<=0: return 0
  try:
    newp=sub.Popen(UPTIME,stdout=sub.PIPE,bufsize=50000)
  except:
    print 'Error launching:',UPTIME
    sys.exit()
  res=newp.stdout.readline().strip()
  print >>out, "---------------------------------------------------------"
  print >>out, "Launching %d processes on %s" % (howmany,time.asctime())
  print >>out, "UPTIME:",res
  print >>out, "Proc.data: (SIZE/steps),elaps,utime,stime,perc,maxrss,ixrss,idrss,isrss,minflt,majflt,nswap,inblock,oublock,msgsnd,msgrcv,nsignals,nvcsw,nivcsw"
 
  npp=howmany
  pp=[]
  done=[]
  memidx=0.0
  fltidx=0.0
  intidx=0.0
  fact=1.0/howmany
  i=0
  t0=time.time()
  process=[PYTHON,PROCEDURE]
  while howmany:     # launch all processes
    try:
      newp=sub.Popen(process,stdout=sub.PIPE,bufsize=1000)
    except:
      print 'Error launching:',' '.join(process)
      sys.exit()
    newp.myindex=i+1
    pp.append(newp)
    howmany-=1
    i+=1

  sys.stdout.flush()
  for p in pp:
    l=p.wait()

  t1=time.time()
  print >>out, 'Total elapsed time for %d processes: %.2f sec' % (npp,(t1-t0))

  for p in pp:
    l=p.stdout.readline().strip()
    print >>out, '  %d/%d -' % (p.myindex,npp), l
  print >>out

def usage():
  print
  print """Multiple process launcher

Starts an increasing number of concurrent processes and measures the elapsed time.

Usage:

    python multi.py N1 [ N2 N3 ]    # Iterate from N1 to N2 with step N3
                      
"""
  sys.exit()

def filename(me,n1,n2,n3):
   m=re.compile('%s_(\\d+)-.*[.]out' % me)
   cont=filter(lambda x: m.match(x), os.listdir('.'))
   if cont:
      cont.sort()
      o=m.match(cont[-1])
      nf=int(o.group(1))+1
   else:
      nf=0
   outfile='%s_%3.3d-%d-%d-%d.out' % (me,nf,n1,n2,n3)
   return outfile

global out

t0=time.asctime()
if len(sys.argv)< 2 : usage()

n1=int(sys.argv[1])

if len(sys.argv) > 2:
   n2=int(sys.argv[2])
else:
   n2=n1
if len(sys.argv) > 3:
   n3=int(sys.argv[3])
else:
   n3=1

me=os.uname()[1]
me=me.split('.')[0]    # remove domain
outfile=filename(me,n1,n2,n3)

out=open(outfile,'w')
print 'MULTI Vers. %s  - Output to file:' % myVersion,outfile
system='%s %s %s' % (os.uname()[0],os.uname()[2],os.uname()[4])
scipyvers=scipy.version.version
numpyvers=numpy.version.version
pyvers='%d.%d.%d' % (sys.version_info[0],sys.version_info[1],sys.version_info[2])

print >>out, "MULTI Vers. %s running on %s. Start on %s" % (myVersion,me,time.asctime())
print >>out, "Sys Info:",system
print >>out, "Python vers:",pyvers
print >>out, "Numpy vers:",numpyvers
print >>out, "Scipy vers:",scipyvers

i = n1
count=1
while i <= n2: 
  multi(i)
  i+=n3

