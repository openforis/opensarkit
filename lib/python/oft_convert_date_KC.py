!# /usr/bin/python

import datetime
s = '20150108'
d = datetime.datetime.strptime(s, '%Y%m%d') + datetime.timedelta(days=1)
print d
2015-01-09 00:00:00
print d.strftime('%Y%m%d')
20150109
