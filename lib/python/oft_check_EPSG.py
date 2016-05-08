#! /usr/bin/env python

# taken from http://gis.stackexchange.com/questions/7608/shapefile-prj-to-postgis-srid-lookup-table

import sys
from osgeo import osr

def esriprj2standards(shapeprj_path):
   prj_file = open(shapeprj_path, 'r')
   prj_txt = prj_file.read()
   srs = osr.SpatialReference()
   srs.ImportFromESRI([prj_txt])
   print 'Shape prj is: %s' % prj_txt
   print 'WKT is: %s' % srs.ExportToWkt()
   print 'Proj4 is: %s' % srs.ExportToProj4()
   srs.AutoIdentifyEPSG()
   print 'EPSG is: %s' % srs.GetAuthorityCode(None)

esriprj2standards(sys.argv[1])
