#! /usr/bin/python

#import the numpy and gdal libraries
import numpy as np
import numpy.ma as ma
from osgeo import gdal
import sys, getopt, os

def main(argv):
   input1 = ''
   input2 = ''
   out1 = ''
   out2 = ''
   try:
      opts, args = getopt.getopt(argv,"hi:o:",["input=","output="])
   except getopt.GetoptError:
      print 'test.py -i <input file> -o <output stack>'
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print 'osk_calc_ts_stats.py -i <input stack> -o <output prefix>' 
         sys.exit()
      elif opt in ("-i", "--input"):
         inputfile = arg
      elif opt in ("-o", "--output"):
         output = arg


   # read input data	
   data   = gdal.Open(inputfile)
   band   = data.GetRasterBand(1)
   arr    = band.ReadAsArray()

    # get input infos for later output
   [cols,rows] = arr.shape
   trans       = data.GetGeoTransform()
   proj        = data.GetProjection()
   nodatav     = band.GetNoDataValue()

   #an empty array/vector in which to store the different bands
   layers = []
#   print layers.shape

   for i in range(1, data.RasterCount+1):
       layers.append(data.GetRasterBand(i).ReadAsArray())

   #print layers
   #dstack will take a number of n by m in tuple or list and stack them
   #in the 3rd dimension so you end up with raster_stack being n by m by i, 
   #where i is the number of bands
   print layers
   raster_stack = np.dstack(layers)
   print raster_stack
   #call built in numpy functions std and mean, with a specified axis. if   
   #no axis is set then it will return a number (scaler) but specifying
   #axis=2 means it will calculate along the 'depth' axis, per pixel.
   #with the return being n by m, the shape of each band.
   stdev = np.std(raster_stack, axis=2)
   mean = np.mean(raster_stack, axis=2)
   ds_sum = np.sum(raster_stack, axis=2)
   med = np.median(raster_stack, axis=2)
   var = np.var(raster_stack, axis=2)
   # Create the file, using the information from the original file
   outdriver = gdal.GetDriverByName("GTiff")
   outdata_mean   = outdriver.Create(str(output + "_mean.tif"), rows, cols, 1, gdal.GDT_Float32)
   outdata_stdev   = outdriver.Create(str(output + "_stdev.tif"), rows, cols, 1, gdal.GDT_Float32)
   outdata_sum   = outdriver.Create(str(output + "_sum.tif"), rows, cols, 1, gdal.GDT_Float32)
   outdata_med   = outdriver.Create(str(output + "_med.tif"), rows, cols, 1, gdal.GDT_Float32)
   outdata_var   = outdriver.Create(str(output + "_var.tif"), rows, cols, 1, gdal.GDT_Float32)

   # Write the array to the file, which is the original array in this example
   outdata_mean.GetRasterBand(1).WriteArray(mean)
   outdata_stdev.GetRasterBand(1).WriteArray(stdev)
   outdata_sum.GetRasterBand(1).WriteArray(ds_sum)
   outdata_med.GetRasterBand(1).WriteArray(med)
   outdata_var.GetRasterBand(1).WriteArray(var)

   # Set a no data value if required
   outdata_mean.GetRasterBand(1).SetNoDataValue(nodatav)
   outdata_stdev.GetRasterBand(1).SetNoDataValue(nodatav)
   outdata_sum.GetRasterBand(1).SetNoDataValue(nodatav)
   outdata_med.GetRasterBand(1).SetNoDataValue(nodatav)
   outdata_var.GetRasterBand(1).SetNoDataValue(nodatav)

   # Georeference the image
   outdata_mean.SetGeoTransform(trans)
   outdata_stdev.SetGeoTransform(trans)
   outdata_sum.SetGeoTransform(trans)
   outdata_med.SetGeoTransform(trans)
   outdata_var.SetGeoTransform(trans)

   # Write projection information
   outdata_mean.SetProjection(proj)
   outdata_stdev.SetProjection(proj)
   outdata_sum.SetProjection(proj)
   outdata_med.SetProjection(proj)
   outdata_var.SetProjection(proj)

if __name__ == "__main__":
   main(sys.argv[1:])
