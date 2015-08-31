#! /home/avollrath/miniconda/bin/python

#conda install -c osgeo rsgis_scripts rsgislib kealib scikit-learn rios

import sys, getopt, os
import rsgislib
from rsgislib import imagecalc
from rsgislib import imageutils
from rsgislib.imagecalc import BandDefn


def main(argv):
   inputlist = ''
   outstack = ''
   try:
      opts, args = getopt.getopt(argv,"hi:o:",["inputlist=","outstack="])
   except getopt.GetoptError:
      print 'test.py -i <input list text file> -o <output stack>'
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print 'test.py -l <list of images> -o <output stack>' 
         sys.exit()
      elif opt in ("-i", "--inputlist"):
         inputlist = arg
      elif opt in ("-o", "--outstack"):
         outstack = arg
   print 'Input list is:', 		inputlist
   print 'Output file is:', 		outstack

   # create image stack
   with open(inputlist, 'r') as f:
   	bands_list = [line.strip() for line in f]
   with open(inputlist, 'r') as f:
      band_names = [line.strip() for line in f]
   
	#band_names = ['HH', 'HV', 'HH_HV', 'Mean_HH', 'Mean_HV', 'Var_HH', 'Var_HV','DEM_H', 'DEM_S', 'DEM_A']    #, 'dem', 'aspect', 'slope']
   gdaltype = rsgislib.TYPE_32FLOAT
   imageutils.stackImageBands(bands_list, band_names, outstack, -9999, 0, 'KEA', rsgislib.TYPE_32FLOAT)  

if __name__ == "__main__":
   main(sys.argv[1:])

