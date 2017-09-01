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

from osgeo import gdal, ogr, gdal_array
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


def zonal_stats(vector_path, raster_path, nodata_value=None, global_src_extent=False):

    # open raster file
    rds = gdal.Open(raster_path, GA_ReadOnly)

    # get geo data
    rgt = rds.GetGeoTransform()
    assert(rds)

    # get number of bands
    bands = rds.RasterCount

    # open vector file
    vds = ogr.Open(vector_path, GA_ReadOnly)  # TODO maybe open update if we want to write stats
    assert(vds)
    # get the layer
    vlyr = vds.GetLayer(0)

    # count valid features
    #nr_of_feat = vlyr.GetFeatureCount()
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
    # create an array for final stats with number of features
    final_stats = np.arange(nr_of_feat)
    #mean = np.empty((nr_of_feat, bands))
    # create a python list to fill during subsequent loop
    mean = [[0 for _ in range(bands)] for _ in range(nr_of_feat)]
    print mean
    #training = np.empty((nr_of_feat))
    training = []
    for x in xrange (1, bands + 1):

        print "run:" + str(x)
        rb = rds.GetRasterBand(x)

        #vlyr = vds.GetLayer(0)

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

        # Loop through vectors
        stats = []
        feat = None

        # reset feature reading for every band
        feat = vlyr.ResetReading()
        # get the first feature (subsequent features call is in the loop)
        feat = vlyr.GetNextFeature()


        i = 0
        # loop through the features
        while feat is not None:

            label = feat.GetField("biomass")
            print "label: " + str(label)

            if label is not None:
            # extract the training (we only need once)
                if x == 1:
                    label = feat.GetField("biomass")
            #        print "label: " + str(label)

                    training.append(feat.GetField("biomass"))
                    print training
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
                #print band_mean
                feature_stats = {
                    #'min': float(masked.min()),
                    band_mean: float(masked.mean())}#,
                    #'max': float(masked.max()),
                    #'std': float(masked.std()),
                    #'sum': float(masked.sum()),
                    #'count': int(masked.count()),
                    #'fid': int(feat.GetFID())}

                #stats_1.(mean)

                #stats.append(feature_stats)
                ar_row = i
                ar_col = x - 1
                i = i + 1
                print i
                #print "row:" + str(ar_row)
                #print "col:" + str(ar_col)

                # fill the array with the respective values
                mean[ar_row][ar_col] = float(masked.mean())
                #print "mean:" + str(float(masked.mean()))

            rvds = None
            mem_ds = None
            feat = vlyr.GetNextFeature()


        #final_stats = np.append(final_stats, mean)
        #print final_stats
        #print stats


    # python lists to numpy array
    training = np.array(training)
    mean = np.array(mean)
    print "mean:" + str(mean)
    print "training" + str(training)

    vds = None
    #rds = None

    rf = RandomForestRegressor(n_estimators=20, oob_score=True)
    #print np.shape(training)
    #print np.shape(mean)
    print training.shape
    print mean.shape
    # Fit our model to training data
    rf = rf.fit(mean, training)
    print('Our OOB prediction of accuracy is: {oob}%'.format(oob=rf.oob_score_ * 100))

    bands = [1, 2, 3] # need to be changed]
    for b, imp in zip(bands, rf.feature_importances_):
        print('Band {b} importance: {imp}'.format(b=b, imp=imp))

    img = np.zeros((rds.RasterYSize, rds.RasterXSize, rds.RasterCount),
               gdal_array.GDALTypeCodeToNumericTypeCode(rds.GetRasterBand(1).DataType))

    for b in range(img.shape[2]):
        img[:, :, b] = rds.GetRasterBand(b + 1).ReadAsArray()

    new_shape = (img.shape[0] * img.shape[1], img.shape[2])
    img_as_array = img.reshape(new_shape)
    #print img_as_array[]
    print('Reshaped from {o} to {n}'.format(o=img.shape,
                                        n=img_as_array.shape))
    print "Score" + str(rf.score(mean, training))
    classification = rf.predict(img_as_array)
    # Reshape our classification map
    classification = classification.reshape(img[:, :, 0].shape)
    print classification.shape

    return classification

if __name__ == "__main__":
    opts = {'VECTOR': sys.argv[1], 'RASTER': sys.argv[2]}

    stats = zonal_stats(opts['VECTOR'], opts['RASTER'], 0)
    plt.imshow(stats, cmap=plt.cm.summer)
    colorbar()
    #plt.show
    plt.savefig('/home/avollrath/test.png')
    try:
        from pandas import DataFrame
        #print DataFrame(stats)
    except ImportError:
        import json
        print json.dumps(stats, indent=2)
