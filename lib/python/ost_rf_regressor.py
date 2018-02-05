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
#from sklearn.ensemble import ExtraTreesRegressor
from sklearn import cross_validation

from sklearn.feature_selection import SelectFromModel

from sklearn.metrics import r2_score
from sklearn.metrics import mean_squared_error
from sklearn.metrics import mean_absolute_error
from sklearn.metrics import explained_variance_score

import matplotlib.pyplot as plt
from pylab import *
from math import sqrt

import numpy as np

from itertools import product

import sys
import os

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

            #label2 = feat.GetField("Id")
            #print "label2: " + str(label2)


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
    training = np.array(training)
    mean = np.array(mean)

    # we do not need the vector layr anymore
    vds = None

    # prepare paramtere testing
    PARAMETER_GRID = [
        (50, 75), #, 100, 125, 150, 200), # nr. of estimators
        ('auto', 'sqrt'), #, 'log2'),     # max nr. of features
        (1, 2), #, 3, 5)                  # min nr. of leaves
    ]

    # set a preliminary score
    best_score = float("-inf")
    best_tot_score = float("-inf")
    best_r2 = float("-inf")

    print " Testing for different parameter sets of the RF classifier with all features ..."
    for n, f, l in product(*PARAMETER_GRID):
        print " Combination of " + str(n) + " estimators, " + str(f) + " feature subset and " + str(l) + " as minimum number of leaves"
        # create the rf classifier
        rf_initial = RandomForestRegressor(n_estimators=n,
                                   max_features=f ,
                                   min_samples_leaf=l,
                                   oob_score=True,
                                   n_jobs=-1)
        # Fit our model to training data
        rf_initial.fit(mean,training)
        splits = int(round(nr_of_feat / 5))
        cv_predicted = cross_validation.cross_val_predict(rf_initial, mean, training,  cv=splits)
        r2 = r2_score(training, cv_predicted)
        print " oob model: " + str(rf_initial.oob_score_)
        print " r^2 model: " + str(r2)
        tot_score = (2 * r2 + rf_initial.oob_score_) / 3

        if tot_score > best_tot_score:
            best_tot_score=tot_score
            best_r2 = r2
            best_score = rf_initial.oob_score_
            print " best oob: " + str(best_score)
            print " best r^2: " + str(r2)
            rf = rf_initial
            est, features, leaves = n, f, l

    # get OOB score and score
    oob = rf.oob_score_
    score = rf.score(mean, training)

    # print results of best model
    print( '-------------------------------- ')
    print( ' 1)     Best model using all features:')
    print( '-------------------------------- ')
    print( '   RF paramters: ')
    print( '      Number of estimators: ' + str(est))
    print( '      Max. number of features: ' + str(features))
    print( '      Min. number of samples per leave: ' + str(leaves))
    print( '' )
    print( '   R^2 model score: ' + str(score))
    print( '   OOB prediction score: ' + str(oob))
    print( '   R^2 cross-val score: ' + str(best_r2))
    print( '--------------------------------')

    # create stats and figure files
    outname_fi = os.path.basename(newRasterfn)
    outname_fi = outname_fi.replace(' ', '')[:-4]
    outpath_fi = os.path.dirname(newRasterfn)
    text_file = outpath_fi + '/Stats.' + outname_fi + '.txt'
    fig_file = outpath_fi + '/FeatImp.' + outname_fi + '.jpg'
    fig_file2 = outpath_fi + '/FeatImp.reduced.' + outname_fi + '.jpg'

    # write to stats file
    f = open( text_file, 'w' )
    f.write( '-------------------------------- \n')
    f.write( '1) Best model using all features: \n')
    f.write( '-------------------------------- \n')
    f.write( '   RF parameters: \n')
    f.write( '      Number of estimators: ' + str(est) + ' \n')
    f.write( '      Max. number of features: ' + str(features) + ' \n')
    f.write( '      Min. number of samples per leave: ' + str(leaves) + ' \n')
    f.write( '\n' )
    f.write( '   R^2 model score: ' + str(score) + '\n')
    f.write( '   OOB prediction score: ' + str(oob) + ' \n' )
    f.write( '   R^2 cross-val score: ' + str(best_r2) + '\n' )
    f.write( '-------------------------------- \n')

    print('   The importance of our bands are:')
    f.write('   The importance of our bands are:\n')
    #get band importance
    imps=[]
    bands = range(1, bands + 1)
    for b, imp in zip(bands, rf.feature_importances_):
        print('      Band {b} importance: {imp}'.format(b=b, imp=imp))
        f.write('      Band ' + str(b) + ' importance: ' + str(imp) + '\n' )
        imps.append(imp)

    if "SEPAL" not in os.environ:
        # create a plot for the feature importance
        index = np.arange(b)
        bar_width=0.8
        fig, ax = plt.subplots()
        plt.bar(index + 0.6, imps, bar_width,
                alpha=0.4,
                color='b')
        ax.set_xlabel('Band number')
        ax.set_ylabel('Score')
        plt.xticks(index + 1)
        ax.set_title('Feature importance for RF regressor')

        # save plot to file
        plt.savefig(fig_file)
        plt.show()

    print " Reducing number of input features based on feature importance."
    feat_subset = SelectFromModel(rf, prefit=True)
    mean_new = feat_subset.transform(mean)
    feat_bool = feat_subset.get_support()
    print " " + str(len(mean_new[0])) + " features chosen after model selection."


    print " Testing for different parameter sets of the RF classifier with the selected features ..."
    for n, mf, l in product(*PARAMETER_GRID):
        print " Combination of " + str(n) + " estimators, " + str(mf) + " feature subset and " + str(l) + " as minimum number of leaves"
        # create the rf classifier
        rf_opt = RandomForestRegressor(n_estimators=n,
                                   max_features=mf ,
                                   min_samples_leaf=l,
                                   oob_score=True,
                                   n_jobs=-1)
        # Fit our model to training data
        rf_opt.fit(mean_new,training)
        splits = int(round(nr_of_feat / 5))
        cv_predicted = cross_validation.cross_val_predict(rf_opt, mean_new, training,  cv=splits)
        r2 = r2_score(training, cv_predicted)
        print " oob model: " + str(rf_opt.oob_score_)
        print " r^2 model: " + str(r2)
        tot_score = (2 * r2 + rf_opt.oob_score_) / 3

        if tot_score > best_tot_score:
            best_tot_score=tot_score
            best_r2 = r2
            best_score = rf_opt.oob_score_
            print " best oob : " + str(best_score)
            print " best r^2 : " + str(best_r2)
            rf = rf_opt
            print rf
            est, features, leaves = n, mf, l
            mean = mean_new

    # get OOB score and score
    oob = rf.oob_score_
    score = rf.score(mean, training)

    print rf.feature_importances_

    if mean.shape != mean_new.shape:
        print( '------------------------------------- ')
        print( ' No improvements by feature reduction. ')
        print( '------------------------------------- ')

        f.write( '------------------------------------- \n')
        f.write( ' No improvements by feature reduction. \n')
        f.write( '------------------------------------- \n')
    else:
        # print results of best model
        print( '-------------------------------- ')
        print( ' 1) Best model using reduced set of features:')
        print( '-------------------------------- ')
        print( '   RF paramters: ')
        print( '      Number of estimators: ' + str(est))
        print( '      Max. number of features: ' + str(features))
        print( '      Min. number of samples per leave: ' + str(leaves) + '\n')
        print( '   R^2 model score: ' + str(score))
        print( '   OOB prediction score: ' + str(oob))
        print( '   R^2 cross-val score: ' + str(best_r2))
        print( '-------------------------------- ')

        f.write( '\n')
        f.write( '\n')
        f.write( '-------------------------------- \n')
        f.write( ' 2) Best model using reduced set of features: \n')
        f.write( '-------------------------------- \n')
        f.write( '   RF paramters: \n')
        f.write( '      Number of estimators: ' + str(est) + ' \n')
        f.write( '      Max. number of features: ' + str(features) + ' \n')
        f.write( '      Min. number of samples per leave: ' + str(leaves) + ' \n')
        f.write( '' )
        f.write( '   R^2 model score: ' + str(score) + ' \n' )
        f.write( '   OOB prediction score: ' + str(oob) + ' \n' )
        f.write( '   R^2 cross-val score: ' + str(best_r2) + '\n' )
        f.write( '-------------------------------- \n')

        print('   The importance of our bands are:')
        f.write('   The importance of our bands are:\n')

        imps=[]
        bands=[]
        j=0
        for i in xrange(len(feat_bool)):
            if feat_bool[i] == True:
                band=i+1
                #get band importance
                imp=rf.feature_importances_[j]
                print('      Band ' + str(band) + ' importance: ' + str(imp))
                f.write('      Band ' + str(band) + ' importance: ' + str(imp) + '\n')
                j = j + 1
                imps.append(imp)
                bands.append(band)

        if "SEPAL" not in os.environ:
            # create a plot for the feature importance
            index = np.arange(j)
            bar_width=0.8
            fig, ax = plt.subplots()
            plt.bar(index + 0.6, imps, bar_width,
                    alpha=0.4,
                    color='b')
            ax.set_xlabel('Band number')
            ax.set_ylabel('Score')
            plt.xticks(index + 1, bands)
            #plt.xticks(bands)
            ax.set_title('Feature importance for RF regressor')

            # save plot to file
            plt.savefig(fig_file2)
            plt.show()

    print " Cross-validating the final model (Leave-5-out CV) ..."
    splits = int(round(nr_of_feat / 5))
    cv_predicted = cross_validation.cross_val_predict(rf, mean, training,  cv=splits)
    cv_score = cross_validation.cross_val_score(rf, mean, training, cv=splits, scoring='r2', n_jobs=-1)

    # calculate some quality criteria
    r2 = r2_score(training, cv_predicted)
    mse = mean_squared_error(training, cv_predicted)
    rmse = sqrt(mse)
    mae = mean_absolute_error(training, cv_predicted)
    mape = np.mean(np.abs((training - cv_predicted) / training)) * 100
    evs =  explained_variance_score(training, cv_predicted, multioutput = 'uniform_average')

    print('--------------------------------')
    print(' Final Model cross-validation')
    print('--------------------------------')
    print( " R^2: " + str(r2))
    print( " MAE: " + str(mae))
    print( " MAPE: " + str(mape))
    print( " MSE: " + str(mse))
    print( " RMSE: " + str(rmse))
    print( " EVS: " + str(evs))
    print('--------------------------------')
    print( " Accuracy: %0.2f (+/- %0.2f)" % (cv_score.mean(), cv_score.std() * 2))
    print('--------------------------------')

    f.write('-------------------------------- \n')
    f.write(' Final Model cross-validation\n')
    f.write('--------------------------------\n')
    f.write( " R^2: " + str(r2) + '\n')
    f.write( " MAE: " + str(mae) + '\n')
    f.write( " MAPE: " + str(mape) + '\n')
    f.write( " MSE: " + str(mse) + '\n')
    f.write( " RMSE: " + str(rmse) + '\n')
    f.write( " EVS: " + str(evs) + '\n')
    f.write('--------------------------------\n')
    f.write( " Accuracy: %0.2f (+/- %0.2f)\n" % (cv_score.mean(), cv_score.std() * 2))
    f.write('--------------------------------\n')
    # close our stats file
    f.close()


    # write cross validation data to file


    d = {'measured': training, 'predicted': cv_predicted}
    df = DataFrame(data=d)
    df.to_csv(outpath_fi + '/CV.' + outname_fi + '.csv', ';')

    if "SEPAL" not in os.environ:
        # create a cross-val plot
        y = training
        fig, ax = plt.subplots()
        ax.scatter(training, cv_predicted, edgecolors=(0, 0, 0))
        ax.plot([y.min(), y.max()], [y.min(), y.max()], 'k--', lw=4)
        ax.set_xlabel('Measured')
        ax.set_ylabel('Predicted')
        plt.show()

    print " Create empty output file ..."
    # create out array
    driver = gdal.GetDriverByName('GTIff')
    outRaster = driver.Create(newRasterfn, cols, rows, 1, gdal.GDT_Float32 ,
        options=[           # Format-specific creation options.
        'BIGTIFF=IF_SAFER',
        'BLOCKXSIZE=128'   # must be a power of 2
        'BLOCKYSIZE=128' #    ,  # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
#        'COMPRESS=LZW'
        ] )
    outRaster.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
    outband = outRaster.GetRasterBand(1)
    outRaster.SetProjection(outRasterSRS.ExportToWkt())
    outRaster.GetRasterBand(1).SetNoDataValue(0)

    #
    print " Predicting the model to the dataset and write to output band ..."
    #classify by raster blocksize
    #loop through y direction
    r = 1
    for y in xrange(0, rows, y_block_size):
        if y + y_block_size < rows:
            ysize = y_block_size
        else:
            ysize = rows - y

        # loop throug x direction
        for x in xrange(0, cols, x_block_size):
            if x + x_block_size < cols:
                xsize = x_block_size
            else:
                xsize = cols - x

            # create empty
            img = np.empty((ysize, xsize, len(mean[0])), dtype=data_type_name)

            # loop through the timeseries and fill the stacked array part
            if mean.shape == mean_new.shape:
                # read input according to feature reduction
                j=0
                for i in xrange(len(feat_bool)):
                    if feat_bool[i] == True:
                        i += 0
                        img[:,:,j] = np.array(rds.GetRasterBand(i+1).ReadAsArray(x,y,xsize,ysize))
                        bands[j]=i+1
                        j = j + 1
            else:
                # read full input
                for i in xrange( rds.RasterCount ):
                    i += 0
                    img[:,:,i] = np.array(rds.GetRasterBand(i+1).ReadAsArray(x,y,xsize,ysize))

            # for later masking
            min_val = np.min(img, axis=2)

            # reshape the stacked array for actual classification
            new_shape = (img.shape[0] * img.shape[1], img.shape[2])
            img_as_array = img.reshape(new_shape)

            # do the classification
            classification = rf.predict(img_as_array)

            # Reshape our classification map
            classification = np.array(classification.reshape(img[:, :, 0].shape))

            # mask out data where on eof the values is 0
            classification[min_val == 0] = 0.

            # write part of the array to file
            outband.WriteArray(classification, x, y)

            print (" Run: " + str(r) )
            r = r + 1

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
