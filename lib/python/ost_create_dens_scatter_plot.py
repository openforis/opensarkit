#!/usr/bin/env python

from osgeo import gdal, ogr, gdal_array, osr
from osgeo.gdalconst import *
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
from scipy.stats import gaussian_kde
#from scipy.stats import linregress
from scipy import stats
from sklearn.metrics import mean_squared_error
from math import sqrt

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

def mean_absolute_percentage_error(y_true, y_pred):
    y_true, y_pred = np.array(y_true), np.array(y_pred)
    return np.mean(np.abs((y_true - y_pred) / y_true)) * 100

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
    #assert(vds)
    # get the layer
    vlyr = vds.GetLayer(0)

    # count valid features
    c = 0
    feat = vlyr.GetNextFeature()
    while feat is not None:
        label = feat.GetField(vector_field)
        if label is not None:
            c = c + 1
            nr_of_feat = c

        feat = vlyr.GetNextFeature()

    feat = vlyr.ResetReading()
    print " Reading the training data ..."
    print " Number of training samples:" + str(nr_of_feat)

    # create a python list to fill during subsequent loop for mean and training data
    mean = [[0 for _ in range(bands)] for _ in range(nr_of_feat)]
    training = []

    print " Extracting band values for each training sample ..."
    # extract mean value for each polygon on each band (zonal stats function)
    for x in xrange (1, bands + 1):

        rb = rds.GetRasterBand(x)
        nodata_value = rb.GetNoDataValue()

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

            label = feat.GetField(vector_field)
            #print "label: " + str(label)

            if label is not None:
            # extract the training (we only need once)
                if x == 1:
                    label = feat.GetField(vector_field)
                    training.append(feat.GetField(vector_field))

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
    x = np.array(training)
    y = np.transpose(np.array(mean)).reshape(x.shape)

    # mask for nan
    mx = x[np.logical_and(np.logical_not(np.isnan(x)), np.logical_not(np.isnan(y)))]
    my = y[np.logical_and(np.logical_not(np.isnan(x)), np.logical_not(np.isnan(y)))]

    # # Calculate the point density
    xy = np.vstack([mx,my])
    z = gaussian_kde(xy)(xy)
    #
    x, y = pd.Series(mx, name="x_var"), pd.Series(my, name="y_var")

    meanSquaredError=mean_squared_error(mx, my)
    print("MSE:", meanSquaredError)
    rootMeanSquaredError = sqrt(meanSquaredError)
    print("RMSE:", rootMeanSquaredError)
    MAPE = mean_absolute_percentage_error(mx,my)
    print("MAPE:", MAPE)
    slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
    print("Slope:", slope)
    print("Intercept:", intercept)
    print("R_value:", r_value)
    print("P_value:", p_value)
    print("Std Err:", std_err)

    plt.legend(('data', 'line-regression r={}'.format(r_value)), 'best')
    # # Sort the points by density, so that the densest points are plotted last
    idx = z.argsort()
    mx, my, z = mx[idx], my[idx], z[idx]

    # fit with np.polyfit
    m, b = np.polyfit(x, y, 1)
    #
    fig, ax = plt.subplots()
    ax.scatter(mx, my, c=z, s=10, edgecolor='', cmap=plt.cm.plasma)

    # seabrn stuff
    #ax = sns.regplot(x=x, y=y, marker="+")
    #ax = sns.jointplot(x, y)
#    cmap = sns.cubehelix_palette(as_cmap=True, dark=0, light=1, reverse=False)
#    g = sns.jointplot(x, y, kind="kde", color="b");
#    g.plot_joint(plt.scatter, c="b", s=30, linewidth=1)
#    g.ax_joint.collections[0].set_alpha(0)

    plt.plot(mx, np.poly1d(np.polyfit(mx, my, 1))(mx))
    plt.grid(True)
    plt.xlim((-5,150))
    #plt.ylim((-5,150))
    plt.ylabel('Predicted Biomass')
    plt.xlabel('NFI biomass')

    plt.show()
    # plt.colorbar()

def main():

    from optparse import OptionParser
    from time import time

    usage = "usage: %prog [options] -r inputlayer -v input vector -f vector field -o output file "
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
