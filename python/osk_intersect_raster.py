#! /usr/bin/python

import sys, getopt, os
import gdal
import fnmatch
import math
import csv
#import pyshp
from gdalconst import *
import numpy as np


def main(argv):
   input1 = ''
   input2 = ''
   out1 = ''
   out2 = ''
   try:
      opts, args = getopt.getopt(argv,"ha:b:",["input1=","input2="])
   except getopt.GetoptError:
      print 'test.py -i <input list text file> -o <output stack>'
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print 'test.py -l <list of images> -o <output stack>' 
         sys.exit()
      elif opt in ("-a", "--input1"):
         input1 = arg
      elif opt in ("-b", "--input2"):
         input2 = arg
   #print 'Input Raster 1 is:', 		input1
  # print 'Input Raster 2 is:', 		input2
 #  print 'Output Raster 1 is:', 	out1
#   print 'Output Raster 2 is:', 	out2

# read data into Python
   ds1 = gdal.Open(input1, GA_ReadOnly) 
   ds2 = gdal.Open(input2, GA_ReadOnly) 

# get the metadata (extent etc.) 
   gt1 = ds1.GetGeoTransform() 
   gt2 = ds2.GetGeoTransform() 

# extract the extent
   r1 = [gt1[0], gt1[3], gt1[0] + (gt1[1] * ds1.RasterXSize), gt1[3] + (gt1[5] * ds1.RasterYSize)]
   r2 = [gt2[0], gt2[3], gt2[0] + (gt2[1] * ds2.RasterXSize), gt2[3] + (gt2[5] * ds2.RasterYSize)]

# get the intersect region
   intersection = [max(r1[0], r2[0]), min(r1[1], r2[1]), min(r1[2], r2[2]), max(r1[3], r2[3])]
   print intersection

# crop the datasets to the common region
   #os.system('gdalwarp -te ' + str(intersection[0]) + ' ' +  str(intersection[3])  + ' ' +  str(intersection[2]) + ' ' +  str(intersection[1]) + ' -dstnodata \"0\" -overwrite ' + input1 + ' ' + out1) 
   #os.system('gdalwarp -te ' + str(intersection[0]) + ' ' +  str(intersection[3])  + ' ' +  str(intersection[2]) + ' ' +  str(intersection[1]) + ' -dstnodata \"0\" -overwrite ' + input2 + ' ' + out2) 


if __name__ == "__main__":
   main(sys.argv[1:])

