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

# classifiers
from sklearn.ensemble import RandomForestRegressor
#from sklearn.ensemble import ExtraTreesRegressor

# outlier detection
from sklearn.covariance import EllipticEnvelope
from sklearn import svm

#from sklearn.ensemble import IsolationForest

# cross validation
from sklearn.cross_validation import train_test_split
from sklearn import cross_validation

# feature reduction
from sklearn.feature_selection import SelectFromModel

# stats
from sklearn.metrics import r2_score
from sklearn.metrics import mean_squared_error
from sklearn.metrics import mean_absolute_error
from sklearn.metrics import explained_variance_score

# misc

import sys
import os
from osgeo import gdal, ogr, gdal_array, osr
from osgeo.gdalconst import *
import matplotlib.pyplot as plt
from pylab import *
from math import sqrt
from pandas import DataFrame
import numpy as np
from itertools import product
from scipy import stats


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

def training_extract(raster_path, vector_path, vector_field, global_src_extent=False):

    # open raster file and get info
    rds = gdal.Open(raster_path, GA_ReadOnly)
    rgt = rds.GetGeoTransform()
    assert(rds)
    bands = rds.RasterCount

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
                    label2 = feat.GetField('id')
                    print label2
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
    return mean, training

    # we do not need the vector layr anymore
    vds = None


def outlier_removal(features, samples):

    outliers_fraction = 0.1


    #clf = EllipticEnvelope(contamination=.1)
    clf = EllipticEnvelope(contamination=.1)
    #clf = svm.OneClassSVM(nu=0.95 * outliers_fraction + 0.05,
    #                                 kernel="rbf", gamma=0.1)
    clf.fit(features, samples)
    y_pred = clf.decision_function(features).ravel()
    threshold = stats.scoreatpercentile(y_pred,
                                        100 * outliers_fraction)

    y_pred_new = y_pred > threshold
    print y_pred_new
    #print samples[y_pred_new]
    #print samples.shape
    print samples[y_pred_new].shape
    print features.shape
    print features[y_pred_new].shape

    return features[y_pred_new], samples[y_pred_new]

def outlier_removal2(features, samples, cv_predict):

    outliers_fraction = 0.1

    print cv_predict.shape
    print samples.shape
    test = np.column_stack((cv_predict, samples))
    #clf = EllipticEnvelope(contamination=.1)
    clf = EllipticEnvelope(contamination=.1)
    #clf = svm.OneClassSVM(nu=0.95 * outliers_fraction + 0.05,
    #                                 kernel="rbf", gamma=0.1)
    clf.fit(test)
    y_pred = clf.decision_function(test).ravel()
    threshold = stats.scoreatpercentile(y_pred,
                                        100 * outliers_fraction)

    y_pred_new = y_pred > threshold
    print y_pred_new
    #print samples[y_pred_new]
    print samples.shape
    print samples[y_pred_new].shape
    print features.shape
    print features[y_pred_new].shape

    return features[y_pred_new], samples[y_pred_new]


def extract_stats(nest, mfeatures, mleaves, nr_train, nr_test, model_r2, oob, cv_training, cv_predicted, test_training, test_predicted, newRasterfn):

    print test_training
    print test_predicted
    # create stats and figure files
    outname_fi = os.path.basename(newRasterfn)
    outname_fi = outname_fi.replace(' ', '')[:-4]
    outpath_fi = os.path.dirname(newRasterfn)
    text_file = outpath_fi + '/Stats.' + outname_fi + '.txt'
    fig_file = outpath_fi + '/FeatImp.' + outname_fi + '.jpg'

    # calculate cross-validated statistics
    cv_r2 = r2_score(cv_training, cv_predicted)
    cv_mse = mean_squared_error(cv_training, cv_predicted)
    cv_rmse = sqrt(cv_mse)
    cv_mae = mean_absolute_error(cv_training, cv_predicted)
    cv_mape = np.mean(np.abs((cv_training - cv_predicted) / cv_training)) * 100
    cv_evs =  explained_variance_score(cv_training, cv_predicted, multioutput = 'uniform_average')

    # write out training data and cv to textfile
    d = {'measured': cv_training, 'predicted': cv_predicted}
    df = DataFrame(data=d)
    df.to_csv(outpath_fi + '/CV.' + outname_fi + '.csv', ';')

    if test_training:
        # calculate test-data statistics
        test_r2 = r2_score(test_training, test_predicted)
        test_mse = mean_squared_error(test_training, test_predicted)
        test_rmse = sqrt(test_mse)
        test_mae = mean_absolute_error(test_training, test_predicted)
        test_mape = np.mean(np.abs((test_training - test_predicted) / test_training)) * 100
        test_evs =  explained_variance_score(test_training, test_predicted, multioutput = 'uniform_average')

        # write out training data and cv to textfile
        d = {'measured': test_training, 'predicted': test_predicted}
        df = DataFrame(data=d)
        df.to_csv(outpath_fi + '/Val.' + outname_fi + '.csv', ';')

    # print results of best model
    print( '------------------------------------------ ')
    print( ' Best RF regression model evaluation:')
    print( '------------------------------------------ ')
    print( ' RF paramters: ')
    print( '   Number of training samples: ' + str(nr_train))
    print( '   Number of test samples: ' + str(nr_test))
    print( '   Number of estimators: ' + str(nest))
    print( '   Max. number of features: ' + str(mfeatures))
    print( '   Min. number of samples per leave: ' + str(mleaves))
    print( '' )
    print( ' RF self-assessment:')
    print( '   R^2 model score: ' + str(model_r2))
    print( '   OOB cross-val score: ' + str(oob))
    print( '')
    print( ' Leave k-out cross-validation (k=5):')
    print( '   R^2 : ' + str(cv_r2))
    print( '   MSE : ' + str(cv_mse))
    print( '   RMSE : ' + str(cv_rmse))
    print( '   MAE : ' + str(cv_mae))
    print( '   MAPE : ' + str(cv_mape))
    print( '   EVS : ' + str(cv_evs))

    if test_training:
        print('')
        print( ' Validation on test data')
        print( '   R^2 : ' + str(test_r2))
        print( '   MSE : ' + str(test_mse))
        print( '   RMSE : ' + str(test_rmse))
        print( '   MAE : ' + str(test_mae))
        print( '   MAPE : ' + str(test_mape))
        print( '   EVS : ' + str(test_evs))
        print( '------------------------------------------ ')

    # write to stats file
    f = open( text_file, 'w' )
    f.write( '---------------------------------------- \n')
    f.write( ' Best RF regression model evaluation: \n')
    f.write( '---------------------------------------- \n')
    f.write( ' RF parameters: \n')
    f.write( '   Number of training samples: ' + str(nr_train) + ' \n')
    f.write( '   Number of test samples: ' + str(nr_test) + ' \n')
    f.write( '   Number of estimators: ' + str(nest) + ' \n')
    f.write( '   Max. number of features: ' + str(mfeatures) + ' \n')
    f.write( '   Min. number of samples per leave: ' + str(mleaves) + ' \n')
    f.write( '\n' )
    f.write( ' RF self assessment: \n')
    f.write( '   R^2 model score: ' + str(model_r2) + '\n')
    f.write( '   OOB prediction score: ' + str(oob) + ' \n' )
    f.write( '\n' )
    f.write( ' Leave k-out cross-validation (k=5): \n')
    f.write( '   R^2 : ' + str(cv_r2) + '\n' )
    f.write( '   MSE : ' + str(cv_mse) + '\n')
    f.write( '   RMSE : ' + str(cv_rmse) + '\n')
    f.write( '   MAE : ' + str(cv_mae) + '\n')
    f.write( '   MAPE : ' + str(cv_mape) + '\n')
    f.write( '   EVS : ' + str(cv_evs) + '\n')

    if test_training:
        f.write( '\n' )
        f.write( ' Validation on test datas: \n')
        f.write( '   R^2 : ' + str(test_r2) + '\n' )
        f.write( '   MSE : ' + str(test_mse) + '\n')
        f.write( '   RMSE : ' + str(test_rmse) + '\n')
        f.write( '   MAE : ' + str(test_mae) + '\n')
        f.write( '   MAPE : ' + str(test_mape) + '\n')
        f.write( '   EVS : ' + str(test_evs) + '\n')

    f.write( '--------------------------------------- \n')
    f.close

def band_importance(bands, fi, newRasterfn, feat_bool = None):

    outname_fi = os.path.basename(newRasterfn)
    outname_fi = outname_fi.replace(' ', '')[:-4]
    outpath_fi = os.path.dirname(newRasterfn)
    fig_file = outpath_fi + '/FeatImp.' + outname_fi + '.jpg'
    #f = open( text_file, 'w' )

    print('   The importance of our bands are:')
    #f.write('   The importance of our bands are:\n')
    imps=[]
    if feat_bool is None:
        bands = range(1, bands + 1)
        for b, imp in zip(bands, fi):
            print('      Band {b} importance: {imp}'.format(b=b, imp=imp))
            #f.write('      Band ' + str(b) + ' importance: ' + str(imp) + '\n' )
            imps.append(imp)
    else:
        b = 0
        bands=[]
        for i in xrange(len(feat_bool)):
            if feat_bool[i] == True:
                band=i+1
                #get band importance
                imp=fi[b]
                print('      Band ' + str(band) + ' importance: ' + str(imp))
                #f.write('      Band ' + str(band) + ' importance: ' + str(imp) + '\n')
                b = b + 1
                imps.append(imp)
                bands.append(band)

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
        plt.xticks(index + 1, bands)
        ax.set_title('Feature importance for RF regressor')

        # save plot to file
        plt.savefig(fig_file)
        plt.show()

def rf_regressor(features, samples, newRasterfn, best_tot_score = float("-inf"), feat_bool = None, perc_split = 0.1):

    # get the initial best score for multiple execution
    initial_best_score = best_tot_score
    best_rf = None

    # split training and test data
    feat_train, feat_test, samp_train, samp_test = train_test_split(features, samples, test_size=perc_split)

    # RF parameters to be tested
    PARAMETER_GRID = [
        (50, 75, 100, 125, 150, 200), # nr. of estimators
        ('auto', 'sqrt', 'log2'),     # max nr. of features
        (1, 2, 3, 5, 10, 15)          # min nr. of leaves
    ]

    print " Testing for different parameter sets of the RF classifier with all features ..."
    # loop through all combinations of the parameter grid
    for ne, mf, ml in product(*PARAMETER_GRID):

        print " Combination of " + str(ne) + " estimators, " + str(mf) + " feature subset and " + str(ml) + " as minimum number of leaves"
        # create the rf classifier
        rf = RandomForestRegressor(n_estimators=ne,
                                   max_features=mf,
                                   min_samples_leaf=ml,
                                   oob_score=True,
                                   n_jobs=-1)

        # Fit our model to training data
        rf.fit(feat_train,samp_train)

        # get model perfomance
        oob = rf.oob_score_
        # calculate model self performance
        model_r2 = rf.score(feat_train, samp_train)

        # validation by tets data
        if perc_split > 0:
            test_predicted = rf.predict(feat_test)
            test_r2 = r2_score(samp_test,test_predicted)
        # cross-validation
        splits = int(round(len(samples) / 5))
        cv_predicted = cross_validation.cross_val_predict(rf, feat_train, samp_train,  cv=splits)
        cv_r2 = r2_score(samp_train, cv_predicted)
        #cv_predicted = cross_validation.cross_val_predict(rf, features, samples,  cv=splits)
        #cv_r2 = r2_score(samples, cv_predicted)

        # calculate a final score based on 2/3 CV and 1/3 OOB
        tot_score = (2 * cv_r2 + oob) / 3
        #tot_score = test_r2
        # print out the current scores
        print " R^2 model score: " + str(model_r2)
        print " OOB RF score: " + str(oob)
        print " r^2 CV score: " + str(cv_r2)

        if perc_split > 0:
            print " r^2 test score: " + str(test_r2)

        # adapt new model if tot score is higher
        if tot_score > best_tot_score:

            # save best scores
            best_model_r2 = model_r2
            best_oob = oob
            best_cv_r2 = cv_r2
            best_tot_score=tot_score
            best_cv_predicted = cv_predicted
            nest, mfeatures, mleaves = ne, mf, ml
            best_rf = rf
            best_fi = rf.feature_importances_

            # rint out best scores
            print " best RF OOB: " + str(best_oob)
            print " best CV R^2: " + str(best_cv_r2)

            if perc_split > 0:
                best_test_r2 = test_r2
                best_test_predicted = test_predicted
                print " best test R^2: " + str(best_test_r2)

            else:
                best_test_predicted = []
                samp_test = []

    if best_tot_score > initial_best_score:
        extract_stats(nest, mfeatures, mleaves, len(samp_train), len(samp_test), best_model_r2, best_oob, samp_train,
                      best_cv_predicted, samp_test, best_test_predicted, newRasterfn )
        band_importance(len(features[0]), best_fi, newRasterfn, feat_bool )

    return best_rf, best_tot_score

def rf_feat_reduction(rf_model, features):

    print " Reducing number of input features based on feature importance."
    subset_model = SelectFromModel(rf_model, prefit=True)
    feat_subset = subset_model.transform(features)
    feat_bool = subset_model.get_support()
    print " " + str(len(feat_subset[0])) + " features chosen after model selection."
    return feat_subset, feat_bool

def rf_apply(rf_model, raster_path, newRasterfn, feat_subset = None, feat_bool = None):

    # open raster file
    rds = gdal.Open(raster_path, GA_ReadOnly)
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

    print " Predicting the model to the dataset and write to output band ..."

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

            # loop through the timeseries and fill the stacked array part
            if feat_bool is not None:
                # create empty
                img = np.empty((ysize, xsize, len(feat_subset[0])), dtype=data_type_name)
                j=0
                for i in xrange(len(feat_bool)):
                    if feat_bool[i] == True:
                        i += 0
                        img[:,:,j] = np.array(rds.GetRasterBand(i+1).ReadAsArray(x,y,xsize,ysize))
                        #bands[j]=i+1
                        j = j + 1
            else:
                img = np.empty((ysize, xsize, bands), dtype=data_type_name)
                # read input according to feature reduction
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
            classification = rf_model.predict(img_as_array)

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

    # extract samples
    feat, samp = training_extract(options.iraster,options.ivector,options.vfield)

    # do outlier removal
    #feat, samp = outlier_removal(feat,samp)
    #feat, samp = outlier_removal(feat,samp)

    # run first model
    rf_model_all_feat, rf_score_all_feat = rf_regressor(feat, samp, options.ofile, perc_split = 0.0)

    # outlier removal based on model
    #feat, samp = outlier_removal2(feat, samp_train, cv_predicted)

    # run model with outlier removed samples
    #rf_model_all_feat, rf_score_all_feat, cv_predicted, samp_train = rf_regressor(feat, samp, options.ofile, perc_split = 0.0)

    # reduce features
    feat_subset_1, feat_bool = rf_feat_reduction(rf_model_all_feat, feat)

    # run second model woth reduced feature
    rf_model_reduced_1, rf_score_red_feat = rf_regressor(feat_subset_1, samp, options.ofile,
                                                         rf_score_all_feat, feat_bool, perc_split = 0.0)

    # apply best selected model
    if rf_score_all_feat >= rf_score_red_feat:
            rf_apply(rf_model_all_feat, options.iraster, options.ofile)
    else:
            rf_apply(rf_model_reduced_1, options.iraster, options.ofile, feat_subset_1, feat_bool)

    #
    print 'time elapsed:', time() - currtime

if __name__ == "__main__":
        main()
