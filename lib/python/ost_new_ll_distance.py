#! /usr/bin/python

# thanks to
# https://stackoverflow.com/questions/7222382/get-lat-long-given-current-point-distance-and-bearing
# and
# http://www.movable-type.co.uk/scripts/latlong.html

#
# import math
#
# R = 6378.1 #Radius of the Earth
# #brng = 1.57 #Bearing is 90 degrees converted to radians.
# brng = 1.57 #Bearing is 315 degrees converted to radians.
# d = 0.25 #Distance in km
#
# #lat2  52.20444 - the lat result I'm hoping for
# #lon2  0.36056 - the long result I'm hoping for.
#
# lat1 = math.radians(10.75) #Current lat point converted to radians
# lon1 = math.radians(35.75) #Current long point converted to radians
#
# lat2 = math.asin( math.sin(lat1)*math.cos(d/R) +
#                 math.cos(lat1)*math.sin(d/R)*math.cos(brng))
#
# lon2 = lon1 + math.atan2(math.sin(brng)*math.sin(d/R)*math.cos(lat1),
#                 math.cos(d/R)-math.sin(lat1)*math.sin(lat2))
#
# lat2 = math.degrees(lat2)
# lon2 = math.degrees(lon2)
#

import geopy
from geopy.distance import VincentyDistance
from geopy.distance import great_circle
# given: lat1, lon1, b = bearing in degrees, d = distance in kilometers

lat1=10.75089
lon1=37.75082

b=315
d=0.25
origin = geopy.Point(lat1, lon1)
destination = VincentyDistance(kilometers=d).destination(origin, b)
#destination = great_circle(kilometers=d).destination(origin, b)

lat2, lon2 = destination.latitude, destination.longitude

print(lat2)
print(lon2)
