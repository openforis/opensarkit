#! /usr/bin/python

# import packages
from optparse import OptionParser
from ost_io_ops import *
import numpy as np

# main function
def main():
    usage = "usage: %prog [options] -i inputfile -o outputfile prefix"
    parser = OptionParser()
    parser.add_option("-i", "--inputfile", dest="ifile",
                      help="write report to FILE", metavar="INPUTFILE")

    parser.add_option("-o", "--outputfile", dest="ofile",
                      help="write report to FILE", metavar="OUTPUTFILE PREFIX")

    (options, args) = parser.parse_args()

    if not options.ifile:
        parser.error("Inputfile is empty")
        print usage

    if not options.ofile:
        parser.error("Outputfile is empty")
        print usage

    # Convert Raster to array
    rasterArray = raster3D2array3D(options.ifile)
    print "----------------------------------------------------------------"
    print " Creating percentile layers from Sentinel-1 time-series products"
    print "----------------------------------------------------------------"
    print "INFO: Calculating the 90th percentile in time ..."
    p90 = np.percentile(rasterArray, 90, axis=0)
    # Write updated array to new raster
    array2raster(options.ifile,options.ofile + ".p90.tif",p90)

    print "INFO: Calculating the 10th percentile in time ..."
    p10 = np.percentile(rasterArray, 10, axis=0)
    # Write updated array to new raster
    array2raster(options.ifile,options.ofile + ".p10.tif",p10)

    print "INFO: Calculating the percentile difference ..."
    pDiff = np.subtract(p90,p10)
    # Write updated array to new raster
    array2raster(options.ifile,options.ofile + ".pDiff.tif",pDiff)

    print "INFO: Calculations finished"

if __name__ == "__main__":
   main()
