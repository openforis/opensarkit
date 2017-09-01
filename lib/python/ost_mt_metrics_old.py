#! /usr/bin/python

# import packages
from ost_io_ops import *
import numpy as np
import scipy
from scipy import stats
from time import time

# main function
def main(src_ds, dst_ds):
        # Convert Raster to array
    #rasterArray = raster3D2array3D(options.ifile)
    rasterArray = raster3D2array3D(src_ds)

    nodatamask = rasterArray[1,:,:] > 0

    print "----------------------------------------------------------------"
    print " Creating MT-metrics from Sentinel-1 time-series products"
    print "----------------------------------------------------------------"


    print " INFO: Calculating the mean value in time ..."
    mean = np.mean(rasterArray, axis=0)
    # Write updated array to new raster
    array2raster(src_ds, dst_ds + ".mean.tif",mean)
    del mean

    print " INFO: Calculating the maximum value in time ..."
    maximum = np.amax(rasterArray, axis=0)
    # Write updated array to new raster
    array2raster(src_ds, dst_ds + ".max.tif",maximum)
    del maximum

    print " INFO: Calculating the minimum value in time ..."
    minimum = np.amin(rasterArray, axis=0)
    # Write updated array to new raster
    array2raster(src_ds, dst_ds + ".min.tif",minimum)
    del minimum

    print " INFO: Calculating the standard deviation in time ..."
    stddev = np.std(rasterArray, axis=0)
    # Write updated array to new raster
    array2raster(src_ds, dst_ds + ".std.tif",stddev)
    del stddev

    print " INFO: Calculating the Coefficient of Variation in time ..."
    stddev = np.std(rasterArray, axis=0)
    # Write updated array to new raster
    array2raster(src_ds, dst_ds + ".cov.tif",stddev)

    #print " INFO: Calculating the argmin in time ..."
    #argmin = np.argmin(rasterArray, axis=0)
    # Write updated array to new raster
    #array2raster(src_ds, dst_ds + ".argmin.tif",argmin)

    #print " INFO: Calculating the argmax in time ..."
    #argmin = np.argmax(rasterArray, axis=0)
    # Write updated array to new raster
    #array2raster(src_ds, dst_ds + ".argmax.tif",argmin)

    #print " INFO: Calculating the skewness in time ..."
    #skew = scipy.stats.skew(rasterArray.astype(np.float32), axis=0)
    # Write updated array to new raster
    #array2FLTraster(src_ds, dst_ds + ".skew.tif",skew)

    #print " INFO: Calculating the kurtosis in time ..."
    #kurt = scipy.stats.kurtosis(rasterArray.astype(np.float32), axis=0)
    # Write updated array to new raster
    #array2FLTraster(src_ds, dst_ds + ".kurt.tif",kurt)

    #print " INFO: Calculating the kurtosis in time ..."
    #linreg = scipy.stats.linregress(mean.astype(np.float32), minimum.astype(np.float32))
    # Write updated array to new raster
    #array2FLTraster(src_ds, dst_ds + ".linreg.tif",linreg)


    #print " INFO: Calculating the coefficient of variation in time ..."
    #np.seterr(divide='ignore')
    #cov = np.divide(stddev,mean)
    # Write updated array to new raster
    #array2raster(src_ds, dst_ds + ".cov.tif",cov)

    print " INFO: Calculations finished"

if __name__ == "__main__":

    from optparse import OptionParser

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

    currtime = time()
    main(options.ifile,options.ofile)
    print 'time elapsed:', time() - currtime
