#!/usr/bin/python3

from datetime import datetime, timedelta
from pytz import timezone
import pytz
from dateutil.parser import parse

#Print all timezones
#AA=pytz.all_timezones
#AA=pytz.common_timezones
#for i in AA:
#    print(i)

fmt = '%Y-%m-%d %H:%M:%S'

now = pytz.utc.localize(datetime.utcnow())
#tz1 = pytz.timezone('America/Santiago')
tz1 = pytz.timezone('US/Mountain')
#tz1 = pytz.timezone('Atlantic/Canary')
nowlocal=now.astimezone(tz1)


dt0=parse(now.strftime(fmt))
dt1=parse(nowlocal.strftime(fmt))

Delta=(dt1-dt0).total_seconds()/3600.

print(int(Delta))
