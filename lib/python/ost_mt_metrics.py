#! /usr/bin/python

# import packages
import gdal, ogr, osr, os
import numpy as np
import numpy.ma as ma
import scipy
from scipy import stats
from time import time

def rescale_from_db(arrayin,minVal,maxVal,datatype):

    # set output min and max
    display_min = 1.
    if datatype == 'uint8':
        display_max = 254.
    elif datatype == 'UInt16':
        display_max = 65535.

    a = minVal - ((maxVal - minVal)/(display_max - display_min))
    x = (maxVal - minVal)/(display_max - 1)
    arrayout = np.round((arrayin - a) / x).astype(datatype)

    return arrayout

def mt_metrics(rasterfn,newRasterfn,mt_type,toPower,rescale_sar, outlier):

    # open raster file
    raster3d = gdal.Open(rasterfn)

    # Get blocksizes for iterating over tiles (chuuks)
    myBlockSize=raster3d.GetRasterBand(1).GetBlockSize();
    x_block_size = myBlockSize[0]
    y_block_size = myBlockSize[1]

    # Get image sizes
    cols = raster3d.RasterXSize
    rows = raster3d.RasterYSize

    # get datatype and transform to numpy readable
    data_type = raster3d.GetRasterBand(1).DataType
    data_type_name = gdal.GetDataTypeName(data_type)

    if data_type_name == "Byte":
        data_type_name = "uint8"

    print " INFO: Importing", raster3d.RasterCount, "bands from", rasterfn

    band=raster3d.GetRasterBand(1)
    geotransform = raster3d.GetGeoTransform()
    originX = geotransform[0]
    originY = geotransform[3]
    pixelWidth = geotransform[1]
    pixelHeight = geotransform[5]
    driver = gdal.GetDriverByName('GTiff')
    ndv = raster3d.GetRasterBand(1).GetNoDataValue()

    # we need this for file creation
    outRasterSRS = osr.SpatialReference()
    outRasterSRS.ImportFromWkt(raster3d.GetProjectionRef())

    # we will need this to create the output just once
    k = 1

    # loop through the metrics
    # create a vector of measures
    if mt_type is '1':
        metrics = ["avg", "max", "min", "std", "cov" ]
    elif mt_type is '2':
        metrics = [ "p90", "p10", "pDiff" ]
    elif mt_type is '3':
        metrics = [ "max", "min" ] # for extent
    elif mt_type is '4':
        metrics = [ "max" ] # for ls map
    elif mt_type is '5':
        metrics = ["avg", "max", "min", "std", "cov" , "skew", "kurt", "argmin", "argmax", "median" ]
    elif mt_type is '6':
        metrics = ["sum"] # for TRMM

    # loop through y direction
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

            # create the blocksized array
            stacked_array_orig=np.empty((raster3d.RasterCount, ysize, xsize), dtype=data_type_name)

            # loop through the timeseries and fill the stacked array part
            for i in xrange( raster3d.RasterCount ):
                i += 0
                stacked_array_orig[i,:,:] = np.array(raster3d.GetRasterBand(i+1).ReadAsArray(x,y,xsize,ysize))

                # convert back to original dB
                if rescale_sar == 'yes':
                    if data_type_name == 'uint8':
                        stacked_array = stacked_array_orig.astype(float) * ( 35. / 254.) + (-30. - (35. / 254.))

                    elif data_type_name == 'UInt16':
                        stacked_array = stacked_array_orig.astype(float) * ( 35. / 65535.) + (-30. - (35. / 65535.))
                    else:
                        stacked_array = stacked_array_orig
                else:
                    stacked_array = stacked_array_orig

            # original nd_mask
            nd_mask = stacked_array_orig[1,:,:] == 0

            # the outlier removal routine
            if outlier == 'yes' and raster3d.RasterCount >= 5:
                # calculate percentiles
                p95 = np.percentile(stacked_array, 95, axis=0)
                p5 = np.percentile(stacked_array, 5, axis=0)

                # we mask out the percetile outliers for std dev calculation
                masked_array = np.ma.MaskedArray(
                                stacked_array,
                                mask = np.logical_or(
                                stacked_array > p95,
                                stacked_array < p5
                                )
                )

                # we calculate new std and mean
                masked_std = np.std(masked_array, axis=0)
                masked_mean = np.mean(masked_array, axis=0)

                # # we mask based on mean +- 2 * stddev
                stacked_array = np.ma.MaskedArray(
                                stacked_array,
                                mask = np.logical_or(
                                stacked_array > masked_mean + masked_std * 4,
                                stacked_array < masked_mean - masked_std * 4,
                                )
                )

            # convert to power
            if toPower == 'yes':
                #print stacked_array.shape
                stacked_array_pow = 10 ** (stacked_array / 10)
                stacked_array = stacked_array_pow
                #print stacked_array.shape

            # we calculate the metrics needed
            for metric in metrics:

                # calculate the specific metric
                if metric == "avg":

                    if k == 1:
                        outRaster_avg = driver.Create(newRasterfn + ".avg.tif", cols, rows, 1, data_type,
                            options=[           # Format-specific creation options.
                            'TILED=YES',
                            'BIGTIFF=IF_SAFER',
                            'BLOCKXSIZE=256',   # must be a power of 2
                            'BLOCKYSIZE=256',  # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
                            'COMPRESS=LZW'
                            ] )
                        outRaster_avg.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
                        outband_avg = outRaster_avg.GetRasterBand(1)
                        outRaster_avg.SetProjection(outRasterSRS.ExportToWkt())
                        if ndv is not None:
                            outRaster_avg.GetRasterBand(1).SetNoDataValue(ndv)

                    # calulate the mean
                    outmetric_avg = np.mean(stacked_array, axis=0)

                    if toPower == 'yes':
                        outmetric_avg_db = 10 * np.log10(outmetric_avg)
                        outmetric_avg = outmetric_avg_db

                    # rescale to actual data type
                    if rescale_sar == 'yes' and data_type_name != 'Float32':
                        outmetric_avg = rescale_from_db(outmetric_avg,-30. ,5. , data_type_name)
                        outmetric_avg[nd_mask == True] = ndv

                    # write to array
                    outband_avg.WriteArray(outmetric_avg, x, y)

                elif metric == "max":

                    if k == 1:
                        outRaster_max = driver.Create(newRasterfn + ".max.tif", cols, rows, 1, data_type,
                            options=[           # Format-specific creation options.
                            'TILED=YES',
                            'BIGTIFF=IF_SAFER',
                            'BLOCKXSIZE=256',   # must be a power of 2
                            'BLOCKYSIZE=256',  # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
                            'COMPRESS=LZW'
                            ] )
                        outRaster_max.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
                        outband_max = outRaster_max.GetRasterBand(1)
                        outRaster_max.SetProjection(outRasterSRS.ExportToWkt())
                        if ndv is not None:
                            outRaster_max.GetRasterBand(1).SetNoDataValue(ndv)

                    # calculate the max
                    outmetric_max = np.max(stacked_array, axis=0)

                    if toPower == 'yes':
                        outmetric_max_db = 10 * np.log10(outmetric_max)
                        outmetric_max = outmetric_max_db

                    # rescale to actual data type
                    if rescale_sar == 'yes' and data_type_name != 'Float32':
                        outmetric_max = rescale_from_db(outmetric_max,-30. ,5. , data_type_name) + 1
                        outmetric_max[nd_mask == True] = ndv

                    outband_max.WriteArray(outmetric_max, x, y)

                elif metric == "min":

                    if k == 1:
                        outRaster_min = driver.Create(newRasterfn + ".min.tif", cols, rows, 1, data_type,
                            options=[           # Format-specific creation options.
                            'TILED=YES',
                            'BIGTIFF=IF_SAFER',
                            'BLOCKXSIZE=256',   # must be a power of 2
                            'BLOCKYSIZE=256',  # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
                            'COMPRESS=LZW'
                            ] )
                        outRaster_min.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
                        outband_min = outRaster_min.GetRasterBand(1)
                        outRaster_min.SetProjection(outRasterSRS.ExportToWkt())
                        if ndv is not None:
                            outRaster_min.GetRasterBand(1).SetNoDataValue(ndv)

                    outmetric_min = np.min(stacked_array, axis=0)

                    if toPower == 'yes':
                        outmetric_min_db = 10 * np.log10(outmetric_min)
                        outmetric_min = outmetric_min_db

                    if rescale_sar == 'yes' and data_type_name != 'Float32':
                        outmetric_min = rescale_from_db(outmetric_min,-30. ,5., data_type_name)
                        outmetric_min[nd_mask == True] = ndv

                    outband_min.WriteArray(outmetric_min, x, y)

                elif metric == "std":

                    if k == 1:
                        outRaster_std = driver.Create(newRasterfn + ".std.tif", cols, rows, 1, data_type,
                                options=[           # Format-specific creation options.
                                'TILED=YES',
                                'BIGTIFF=IF_SAFER',
                                'BLOCKXSIZE=256',   # must be a power of 2
                                'BLOCKYSIZE=256',  # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
                                'COMPRESS=LZW'
                                ] )
                        outRaster_std.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
                        outband_std = outRaster_std.GetRasterBand(1)
                        outRaster_std.SetProjection(outRasterSRS.ExportToWkt())
                        if ndv is not None:
                            outRaster_std.GetRasterBand(1).SetNoDataValue(ndv)

                    outmetric_std = np.std(stacked_array, axis=0)

                    if toPower == 'yes':
                        outmetric_std_db = 10 * np.log10(outmetric_std)
                        outmetric_std = outmetric_std_db

                    if rescale_sar == 'yes' and data_type_name != 'Float32':
                        outmetric_std = rescale_from_db(outmetric_std, 0.00001, 10., data_type_name) + 1
                        outmetric_std[nd_mask == 1] = ndv

                    outband_std.WriteArray(outmetric_std, x, y)

                elif metric == "cov":

                    if k == 1:
                         outRaster_cov = driver.Create(newRasterfn + ".cov.tif", cols, rows, 1, data_type,
                                 options=[           # Format-specific creation options.
                                 'TILED=YES',
                                 'BIGTIFF=IF_SAFER',
                                 'BLOCKXSIZE=256',   # must be a power of 2
                                 'BLOCKYSIZE=256',  # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
                                 'COMPRESS=LZW'
                                 ] )
                         outRaster_cov.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
                         outband_cov = outRaster_cov.GetRasterBand(1)
                         outRaster_cov.SetProjection(outRasterSRS.ExportToWkt())
                         if ndv is not None:
                             outRaster_cov.GetRasterBand(1).SetNoDataValue(ndv)

                    # calulate cov
                    #outmetric_cov = scipy.stats.variation(stacked_array, axis=0)
                    outmetric_cov = np.divide(outmetric_std.astype('float'), outmetric_avg.astype('float'))

                    if rescale_sar == 'yes' and data_type_name != 'Float32':
                        outmetric_cov = rescale_from_db(outmetric_cov, -0.25, 0.25 , data_type_name) + 1
                        outmetric_cov[nd_mask == 1] = 0

                    outband_cov.WriteArray(outmetric_cov, x, y)

                elif metric == "p90":

                    if k == 1:
                        outRaster_p90 = driver.Create(newRasterfn + ".p90.tif", cols, rows, 1, data_type,
                            options=[           # Format-specific creation options.
                            'TILED=YES',
                            'BIGTIFF=IF_SAFER',
                            'BLOCKXSIZE=256',   # must be a power of 2
                            'BLOCKYSIZE=256',  # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
                            'COMPRESS=LZW'
                            ] )
                        outRaster_p90.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
                        outband_p90 = outRaster_p90.GetRasterBand(1)
                        outRaster_p90.SetProjection(outRasterSRS.ExportToWkt())
                        if ndv is not None:
                            outRaster_p90.GetRasterBand(1).SetNoDataValue(ndv)

                    if (data_type_name == 'Float32') or (rescale_sar == 'no'):
                        outmetric_p90 = np.percentile(stacked_array, 90, axis=0)
                        outband_p90.WriteArray(outmetric_p90, x, y)
                    else:
                        outmetric_p90 = np.percentile(stacked_array_db, 90, axis=0)
                        outmetric_p90_res = rescale_from_db(outmetric_p90, -30 , 5 , data_type_name)
                        outband_p90.WriteArray(outmetric_p90_res, x, y)


                elif metric == "p10":

                    if k == 1:
                        outRaster_p10 = driver.Create(newRasterfn + ".p10.tif", cols, rows, 1, data_type,
                            options=[           # Format-specific creation options.
                            'TILED=YES',
                            'BIGTIFF=IF_SAFER',
                            'BLOCKXSIZE=256',   # must be a power of 2
                            'BLOCKYSIZE=256',  # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
                            'COMPRESS=LZW'
                            ] )
                        outRaster_p10.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
                        outband_p10 = outRaster_p10.GetRasterBand(1)
                        outRaster_p10.SetProjection(outRasterSRS.ExportToWkt())
                        if ndv is not None:
                            outRaster_p10.GetRasterBand(1).SetNoDataValue(ndv)

                    if (data_type_name == 'Float32') or (rescale_sar == 'no'):
                        outmetric_p10 = np.percentile(stacked_array, 10, axis=0)
                        outband_p10.WriteArray(outmetric_p10, x, y)
                    else:
                        outmetric_p10 = np.percentile(stacked_array_db, 10, axis=0)
                        outmetric_p10_res = rescale_from_db(outmetric_p10, -30 , 5 , data_type_name)
                        outband_p10.WriteArray(outmetric_p10_res, x, y)


                elif metric == "pDiff":

                    if k == 1:
                        outRaster_pDiff = driver.Create(newRasterfn + ".pDiff.tif", cols, rows, 1, data_type,
                            options=[           # Format-specific creation options.
                            'TILED=YES',
                            'BIGTIFF=IF_SAFER',
                            'BLOCKXSIZE=256',   # must be a power of 2
                            'BLOCKYSIZE=256',  # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
                            'COMPRESS=LZW'
                            ] )
                        outRaster_pDiff.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
                        outband_pDiff = outRaster_pDiff.GetRasterBand(1)
                        outRaster_pDiff.SetProjection(outRasterSRS.ExportToWkt())
                        if ndv is not None:
                            outRaster_pDiff.GetRasterBand(1).SetNoDataValue(ndv)

                    if (data_type_name == 'Float32') or (rescale_sar == 'no'):
                        outmetric_pDiff = np.subtract(outmetric_p90,outmetric_p10)
                        outband_pDiff.WriteArray(outmetric_pDiff, x, y)
                    else:
                        outmetric_pDiff = np.subtract(outmetric_p90_res,outmetric_p10_res)
                        outband_pDiff.WriteArray(outmetric_pDiff, x, y)

                elif metric == "sum":

                    if k == 1:
                        outRaster_sum = driver.Create(newRasterfn + ".sum.tif", cols, rows, 1, data_type,
                            options=[           # Format-specific creation options.
                            'TILED=YES',
                            'BIGTIFF=IF_SAFER',
                            'BLOCKXSIZE=256',   # must be a power of 2
                            'BLOCKYSIZE=256',  # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
                            'COMPRESS=LZW'
                            ] )
                        outRaster_sum.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
                        outband_sum = outRaster_sum.GetRasterBand(1)
                        outRaster_sum.SetProjection(outRasterSRS.ExportToWkt())
                        if ndv is not None:
                            outRaster_sum.GetRasterBand(1).SetNoDataValue(ndv)

                    outmetric = np.sum(stacked_array, axis=0)
                    outband_sum.WriteArray(outmetric, x, y)

            # counter to write the outbup just once
            k = k + 1

def main():

    from optparse import OptionParser

    usage = "usage: %prog [options] -i inputfile -o outputfile prefix -t type of metric -m outlier removal"
    parser = OptionParser()
    parser.add_option("-i", "--inputfile", dest="ifile",
                help="choose an input time-series stack", metavar="<input time-series stack>")

    parser.add_option("-o", "--outputfile", dest="ofile",
                help="Outputfile prefix ", metavar="<utputfile prefix>")

    parser.add_option("-t", "--type", dest="mt_type",
                help="1 = Avg, Max, Min, SD, CoV \t\t\t\t\t"
                     "2 = Percentiles (90th, 10th, 90th - 10th difference)\t\t\t\t\t"
                     "3 = Max, Min\t\t\t\t\t\t\t\t"
                     "4 = Max\t\t\t\t\t\t\t"
                     "5 = Avg, Max, Min, SD, CoV , Skew, Kurt, Argmin, Argmax, Median \t\t\t\t\t "
                     "6 = Sum ",
                metavar="<Number referring to MT metrics>")

    parser.add_option("-p", "--power", dest="toPower",
            help="de-logarithmize to power", metavar="(yes/no) ")

    parser.add_option("-r", "--rescale", dest="rescale_sar",
                help="rescale integer SAR data back to dB (OST specific)", metavar="(yes/no) ")

    parser.add_option("-m", "--outlier", dest="outlier",
                help="mask outliers in the timeseries", metavar="(yes/no) ")

    (options, args) = parser.parse_args()

    if not options.ifile:
        parser.error("Inputfile is empty")
        print usage

    if not options.ofile:
        parser.error("Outputfile is empty")
        print usage

    if not options.mt_type:
        parser.error("Choose one of the metric types")
        print usage

    if not ((options.toPower == 'yes') or (options.toPower == 'no')):
        parser.error("Choose if you need to de-logarithmize from dB to power (yes/no). Note: applies to all time-series created by OST.")
        print usage

    if not ((options.rescale_sar == 'yes') or (options.rescale_sar == 'no')):
        parser.error("Choose if you want to apply rescaling to dB (for Integer SAR data produced by OST). Valid inputs (yes/no).")
        print usage

    if not ((options.outlier == 'yes') or (options.outlier == 'no')):
        parser.error("Choose if you want to remove outliers in the timeseries. Valid inputs (yes/no).")
        print usage

    currtime = time()
    mt_metrics(options.ifile,options.ofile,options.mt_type,options.toPower,options.rescale_sar,options.outlier)
    print 'time elapsed:', time() - currtime


if __name__ == "__main__":
    main()
