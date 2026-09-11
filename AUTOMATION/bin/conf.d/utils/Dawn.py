#!/usr/bin/python
# Version 1.0 - 09/06/2015
# Author Alessio Turchi
import sys, getopt
import ephem

o=ephem.Observer()
o.lat='32:42:4.7124'  
o.long='-109:53:20.6262'
o.elevation=3221
#This is the astronomical dawn with the refraction correction
o.horizon = '-18:34'

if len(sys.argv) > 1:
  year = ''
  month = ''
  day = ''
  try:
    opts, args = getopt.getopt(sys.argv[1:],"hy:m:d:",["year=","month=","day="])
  except getopt.GetoptError:
    print('USAGE: DawnDusk.py -y <year> -m <month> -d <day>')
    sys.exit(2)
  if len(sys.argv) > 7:
    print('USAGE: DawnDusk.py -y <year> -m <month> -d <day>')
    sys.exit(2)
  for opt, arg in opts:
    if opt == '-h':
      print('USAGE: DawnDusk.py -y <year> -m <month> -d <day>')
      sys.exit()
    elif opt in ("-y", "--year"):
      year = arg
    elif opt in ("-m", "--month"):
      month = arg
    elif opt in ("-d", "--day"):
      day = arg
#  print 'year is ', year
#  print 'month is ', month
#  print 'day is ', day
  o.date=year+'/'+month+'/'+day

s=ephem.Sun()  
s.compute()
print(o.next_rising(s))
