#!/usr/bin/env python

"""
Zonal Statistics
Vector-Raster Analysis
Copyright 2013 Matthew Perry
Usage:
  zonal_stats.py VECTOR RASTER
  zonal_stats.py -h | --help
  zonal_stats.py --version
Options:
  -h --help     Show this screen.
  --version     Show version.
"""

#https://gist.github.com/perrygeo/5667173#file-zonal_stats-py-L10

from osgeo import gdal, ogr, gdal_array, osr
from osgeo.gdalconst import *
from pandas import DataFrame
from sklearn.ensemble import RandomForestRegressor
import matplotlib.pyplot as plt
from pylab import *
import numpy as np
import sys
gdal.PushErrorHandler('CPLQuietErrorHandler')


def bbox_to_pixel_offsets(gt, bbox):
    originX = gt[0]
    originY = gt[3]
    pixel_width = gt[1]
    pixel_height = gt[5]
    x1 = int((bbox[0] - originX) / pixel_width)
    x2 = int((bbox[1] - originX) / pixel_width) + 1

    y1 = int((bbox[3] - originY) / pixel_height)
    y2 = int((bbox[2] - originY) / pixel_height) + 1

    xsize = x2 - x1
    ysize = y2 - y1
    return (x1, y1, xsize, ysize)


def regressor(raster_path, vector_path, vector_field, newRasterfn, global_src_extent=False):

    # open raster file
    rds = gdal.Open(raster_path, GA_ReadOnly)

    # get geo data
    rgt = rds.GetGeoTransform()
    assert(rds)

    # get number of bands
    bands = rds.RasterCount
    myBlockSize=rds.GetRasterBand(1).GetBlockSize();
    x_block_size = myBlockSize[0]
    y_block_size = myBlockSize[1]

    # Get image sizes
    cols = rds.RasterXSize
    rows = rds.RasterYSize
    geotransform = rds.GetGeoTransform()
    originX = geotransform[0]
    originY = geotransform[3]
    pixelWidth = geotransform[1]
    pixelHeight = geotransform[5]

    # we need this for file creation
    outRasterSRS = osr.SpatialReference()
    outRasterSRS.ImportFromWkt(rds.GetProjectionRef())
    # get datatype and transform to numpy readable
    data_type = rds.GetRasterBand(1).DataType
    data_type_name = gdal.GetDataTypeName(data_type)

    if data_type_name == "Byte":
        data_type_name = "uint8"

    # open vector file
    vds = ogr.Open(vector_path, GA_ReadOnly)  # TODO maybe open update if we want to write stats
    assert(vds)
    # get the layer
    vlyr = vds.GetLayer(0)

    # count valid features
    c = 0
    feat = vlyr.GetNextFeature()
    while feat is not None:
        label = feat.GetField("biomass")
        if label is not None:
            c = c + 1
            nr_of_feat = c

        feat = vlyr.GetNextFeature()

    feat = vlyr.ResetReading()
    print "features:" + str(nr_of_feat)

    # create a python list to fill during subsequent loop for mean and training data
    mean = [[0 for _ in range(bands)] for _ in range(nr_of_feat)]
    training = []

    # extract mean value for each polygon on each band (zonal stats function)
    for x in xrange (1, bands + 1):

        rb = rds.GetRasterBand(x)
        nodata_value = rb.GetNoDataValue()
        print 'NDV:' + str (nodata_value)

        if nodata_value:
            nodata_value = float(nodata_value)
            rb.SetNoDataValue(nodata_value)

        # create an in-memory numpy array of the source raster data
        # covering the whole extent of the vector layer
        if global_src_extent:
            # use global source extent
            # useful only when disk IO or raster scanning inefficiencies are your limiting factor
            # advantage: reads raster data in one pass
            # disadvantage: large vector extents may have big memory requirements
            src_offset = bbox_to_pixel_offsets(rgt, vlyr.GetExtent())
            src_array = rb.ReadAsArray(*src_offset)

            # calculate new geotransform of the layer subset
            new_gt = (
                (rgt[0] + (src_offset[0] * rgt[1])),
                rgt[1],
                0.0,
                (rgt[3] + (src_offset[1] * rgt[5])),
                0.0,
                rgt[5]
            )

        mem_drv = ogr.GetDriverByName('Memory')
        driver = gdal.GetDriverByName('MEM')

        # reset feature reading for every band
        feat = vlyr.ResetReading()
        # get the first feature (subsequent features call is in the loop)
        feat = vlyr.GetNextFeature()

        # loop through the features and keep an index i per loop
        i = 0
        while feat is not None:

            label = feat.GetField("biomass")
            print "label: " + str(label)

            if label is not None:
            # extract the training (we only need once)
                if x == 1:
                    label = feat.GetField("biomass")
                    training.append(feat.GetField("biomass"))

                # extract the band values
                if not global_src_extent:
                    # use local source extent
                    # fastest option when you have fast disks and well indexed raster (ie tiled Geotiff)
                    # advantage: each feature uses the smallest raster chunk
                    # disadvantage: lots of reads on the source raster
                    src_offset = bbox_to_pixel_offsets(rgt, feat.geometry().GetEnvelope())
                    src_array = rb.ReadAsArray(*src_offset)

                    # calculate new geotransform of the feature subset
                    new_gt = (
                        (rgt[0] + (src_offset[0] * rgt[1])),
                        rgt[1],
                        0.0,
                        (rgt[3] + (src_offset[1] * rgt[5])),
                        0.0,
                        rgt[5]
                    )

                # Create a temporary vector layer in memory
                mem_ds = mem_drv.CreateDataSource('out')
                mem_layer = mem_ds.CreateLayer('poly', None, ogr.wkbPolygon)
                mem_layer.CreateFeature(feat.Clone())

                # Rasterize it
                rvds = driver.Create('', src_offset[2], src_offset[3], 1, gdal.GDT_Byte)
                rvds.SetGeoTransform(new_gt)
                gdal.RasterizeLayer(rvds, [1], mem_layer, burn_values=[1])
                rv_array = rvds.ReadAsArray()

                # Mask the source data array with our current feature
                # we take the logical_not to flip 0<->1 to get the correct mask effect
                # we also mask out nodata values explictly
                masked = np.ma.MaskedArray(
                    src_array,
                    mask=np.logical_or(
                        src_array == nodata_value,
                        np.logical_not(rv_array)
                    )
                )

                band_mean = str(x) + "_mean"

                # index array by bands and feature
                ar_row = i
                ar_col = x - 1
                i = i + 1

                # fill the array with the respective values
                mean[ar_row][ar_col] = float(masked.mean())

            rvds = None
            mem_ds = None
            feat = vlyr.GetNextFeature()

    # python lists to numpy array
    #training = np.array(training)
    mean = np.array(mean)

    # plotting
    plt.style.use('fivethirtyeight')
    fig, ax = plt.subplots()
    ax.plot(range(nr_of_feat), mean, 'ro-')
    plt.show()
    # we do not need the vector layr anymore
    vds = None



def main():

    from optparse import OptionParser
    from time import time

    usage = "usage: %prog [options] -r inputstack -v input vector -f vector field -o output file "
    parser = OptionParser()
    parser.add_option("-r", "--inputraster", dest="iraster",
                help="select an input raster stack", metavar="<input raster stack>")

    parser.add_option("-v", "--inputvector", dest="ivector",
            help="select a training data shape file ", metavar="<input training vector>")

    parser.add_option("-f", "--vectorfield", dest="vfield",
        help="select the column of the shapefile with the biomass values", metavar="<vector field>")

    parser.add_option("-o", "--outputfile", dest="ofile",
                help="Outputfile prefix ", metavar="<utputfile prefix>")

    (options, args) = parser.parse_args()

    if not options.iraster:
        parser.error("Input stack is empty")
        print usage

    if not options.ivector:
        parser.error("Input vector is empty")
        print usage

    if not options.vfield:
        parser.error("No column name selected")
        print usage

    if not options.ofile:
        parser.error("Output file is empty")
        print usage

    currtime = time()
    regressor(options.iraster,options.ivector,options.vfield,options.ofile)
    print 'time elapsed:', time() - currtime

if __name__ == "__main__":
        main()
