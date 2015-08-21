#! /usr/bin/python

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
