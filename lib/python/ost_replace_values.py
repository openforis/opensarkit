#! /usr/bin/python

# import packages
import gdal, ogr, osr, os
import numpy as np
from ost_io_ops import *
from optparse import OptionParser

def main():
    usage = "usage: %prog [options] -i inputfile -o outputfile -rv value to replace -nv new value"
    parser = OptionParser()
    parser.add_option("-i", "--inputfile", dest="ifile",
                      help="write report to FILE", metavar="INPUTFILE")

    parser.add_option("-o", "--outputfile", dest="ofile",
                      help="write report to FILE", metavar="OUTPUTFILE")

    parser.add_option("-r", "--repValue", dest="repValue",
                      help="write report to FILE", metavar="REPVALUE")

    parser.add_option("-n", "--newValue", dest="newValue",
                      help="write report to FILE", metavar="NEWVALUE")

    parser.add_option("-q", "--quiet",
                      action="store_false", dest="verbose", default=True,
                      help="don't print status messages to stdout")

    (options, args) = parser.parse_args()

    if not options.ifile:
        parser.error("Inputfile is empty")
        print usage

    if not options.ofile:
        parser.error("Outputfile is empty")
        print usage

    if not options.repValue:
        parser.error("value ot replace is empty")
        print usage

    if not options.newValue:
        parser.error("new value is empty")
        print usage


    print "Replacing all " + options.repValue + "'s' with " + options.newValue + "."
    # Convert Raster to array
    rasterArray = raster2array(options.ifile)

    # Updata no data value in array with new value
    rasterArray[rasterArray == np.fromstring(options.repValue, dtype=np.uint8)] = np.fromstring(options.newValue, dtype=np.uint8)
    #rasterArray[rasterArray == 0] = 1

    # Write updated array to new raster
    array2raster(options.ifile,options.ofile,rasterArray)

if __name__ == "__main__":
   main()
