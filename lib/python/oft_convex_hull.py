#! /usr/bin/python

# The MIT License (MIT)
# Copyright (c) 2016 Andreas Vollrath

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, including without limitation the rights 
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

import sys, getopt, os
from osgeo import ogr

def main(argv):
   input_file = ''
   output_file = ''
   try:
      opts, args = getopt.getopt(argv,"hi:o:",["input=","output="])
   except getopt.GetoptError:
      print 'osk_convex_hull.py -i <input shapefile > -o <output shapefile>'
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print 'osk_convex_hull.py -i <input shapefile > -o <output shapefile>'
         sys.exit()
      elif opt in ("-i", "--input"):
         input_file = arg
      elif opt in ("-o", "--output"):
         output_file = arg

# Get a Layer
   inShapefile = input_file
   inDriver = ogr.GetDriverByName("ESRI Shapefile")
   inDataSource = inDriver.Open(inShapefile, 0)
   inLayer = inDataSource.GetLayer()

# Collect all Geometry
   geomcol = ogr.Geometry(ogr.wkbGeometryCollection)
   for feature in inLayer:
      geomcol.AddGeometry(feature.GetGeometryRef())

# Calculate convex hull
   convexhull = geomcol.ConvexHull()

# Save extent to a new Shapefile
   outShapefile = output_file
   outDriver = ogr.GetDriverByName("ESRI Shapefile")

# Remove output shapefile if it already exists
   if os.path.exists(outShapefile):
      outDriver.DeleteDataSource(outShapefile)

# Create the output shapefile
   outDataSource = outDriver.CreateDataSource(outShapefile)
   outLayer = outDataSource.CreateLayer("convexhull", geom_type=ogr.wkbPolygon)

# Add an ID field
   idField = ogr.FieldDefn("id", ogr.OFTInteger)
   outLayer.CreateField(idField)

# Create the feature and set values
   featureDefn = outLayer.GetLayerDefn()
   feature = ogr.Feature(featureDefn)
   feature.SetGeometry(convexhull)
   feature.SetField("id", 1)
   outLayer.CreateFeature(feature)

# Close DataSource
   inDataSource.Destroy()
   outDataSource.Destroy()


if __name__ == "__main__":
   main(sys.argv[1:])
