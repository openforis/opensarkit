#! /usr/bin/python

import sys, getopt, os
from osgeo import gdal
import numpy as np


def main(argv):
   input_file = ''
   output_file = ''
   try:
      opts, args = getopt.getopt(argv,"hi:o:",["input=","output="])
   except getopt.GetoptError:
      print 'invert_fmask.py -i <input mask file > -o <output mask file>'
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print 'invert_Fmask.py -i <input mask file > -o <output mask file>'
         sys.exit()
      elif opt in ("-i", "--input"):
         input_file = arg
      elif opt in ("-o", "--output"):
         output_file = arg


#Open our original data as read only
   dataset = gdal.Open(input_file, gdal.GA_ReadOnly)

#Note that unlike the rest of Python, Raster Bands in GDAL are numbered
#beginning with 1.
#I suspect this is to conform to the landsat band naming convention
   band = dataset.GetRasterBand(1)

#Read in the data from the band to a numpy array
   data = band.ReadAsArray()
   data = data.astype(np.float)

#Use numpy, scipy, and whatever Python to make some output data
#That for ease of use should be an array of the same size and dimensions
#as the input data.
   out_data = np.where(abs(data) == 0.,1., 0)
#Note -9999 is a convenience value for null - there's no number for
#transparent values - it's just how you visualise the data in the viewer

#And now we start preparing our output
   driver = gdal.GetDriverByName("GTiff")
   metadata = driver.GetMetadata()

#Create an output raster the same size as the input
   out = driver.Create(output_file,
                    dataset.RasterXSize,
                    dataset.RasterYSize,
                    1, #Number of bands to create in the output
                    gdal.GDT_Int16)

#Copy across projection and transform details for the output
   out.SetProjection(dataset.GetProjectionRef())
   out.SetGeoTransform(dataset.GetGeoTransform()) 

#Get the band to write to
   out_band = out.GetRasterBand(1)

#And write our processed data
   out_band.WriteArray(out_data)


if __name__ == "__main__":
   main(sys.argv[1:])
