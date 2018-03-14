#! /usr/bin/python

# import packages
import gdal, ogr, osr, os
import numpy as np
import numpy.ma as ma
import scipy
from scipy import stats
from time import time

# read in all the metadata of a raster file
def read_input_stack_geos(rasterfn):

    # open raster file
    raster3d = gdal.Open(rasterfn)

    # Get blocksizes for iterating over tiles (chuuks)
    myBlockSize=raster3d.GetRasterBand(1).GetBlockSize();
    x_block_size = myBlockSize[0]
    y_block_size = myBlockSize[1]

    # Get image sizes
    cols = raster3d.RasterXSize
    rows = raster3d.RasterYSize
    bands = raster3d.RasterCount

    # get datatype and transform to numpy readable
    data_type = raster3d.GetRasterBand(1).DataType
    data_type_name = gdal.GetDataTypeName(data_type)

    if data_type_name == "Byte":
        data_type_name = "uint8"

    print " INFO: Importing", raster3d.RasterCount, "bands from", rasterfn

    #band=raster3d.GetRasterBand(1)
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

    # we return a dict of all relevant values
    return {'xB':x_block_size, 'yB': y_block_size, 'cols': cols, 'rows':rows, 'bands':bands, 'dt': data_type, 'dtn':data_type_name, 'ndv':ndv,
            'gtr':geotransform, 'oX':originX, 'oY': originY, 'pW':pixelWidth, 'pH':pixelHeight, 'driver': driver, 'outR':outRasterSRS}

# create an empty raster that is filled later on
def create_2d_raster(newRasterfn, cols, rows, data_type, originX, originY, pixelWidth, pixelHeight, outRasterSRS, driver, ndv):

    outRaster = driver.Create(newRasterfn, cols, rows, 1, data_type,
        options=[           # Format-specific creation options.
        'TILED=YES',
        'BIGTIFF=IF_SAFER',
        'BLOCKXSIZE=128',   # must be a power of 2
        'BLOCKYSIZE=128',  # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
        'COMPRESS=LZW'
        ] )
    outRaster.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
    outband = outRaster.GetRasterBand(1)
    outRaster.SetProjection(outRasterSRS.ExportToWkt())
    if ndv is not None:
        outRaster.GetRasterBand(1).SetNoDataValue(ndv)

    return outRaster

# write chunks of arrays to an already existent raster
def write_chunk_to_raster(outRasterfn, array_chunk, ndv, x, y):

    outRaster = gdal.Open(outRasterfn, gdal.GA_Update)
    outband = outRaster.GetRasterBand(1)

    # write to array
    outband.WriteArray(array_chunk, x, y)

# rescale sar dB dat ot integer format
def rescale_to_int(float_array,minVal,maxVal,datatype):

    # set output min and max
    display_min = 1.
    if datatype == 'uint8':
        display_max = 254.
    elif datatype == 'UInt16':
        display_max = 65535.

    a = minVal - ((maxVal - minVal)/(display_max - display_min))
    x = (maxVal - minVal)/(display_max - 1)
    int_array = np.round((float_array - a) / x).astype(datatype)

    return int_array

# rescale integer scaled sar data back to dB
def rescale_from_int(int_array, data_type_name):

    if data_type_name == 'uint8':
        float_array = int_array.astype(float) * ( 35. / 254.) + (-30. - (35. / 254.))
    elif data_type_name == 'UInt16':
        float_array = int_array.astype(float) * ( 35. / 65535.) + (-30. - (35. / 65535.))

    return float_array

# convert dB to power
def convert_to_pow(dB_array):

    pow_array = 10 ** (dB_array / 10)
    return pow_array

# convert power to dB
def convert_to_dB(pow_array):

    dB_array = 10 * np.log10(pow_array)
    return dB_array

# the outlier removal, needs revision (e.g. use something profound)
def outlier_removal(arrayin):

    # calculate percentiles
    p95 = np.percentile(arrayin, 95, axis=0)
    p5 = np.percentile(arrayin, 5, axis=0)

    # we mask out the percetile outliers for std dev calculation
    masked_array = np.ma.MaskedArray(
                    arrayin,
                    mask = np.logical_or(
                    arrayin > p95,
                    arrayin < p5
                    )
    )

    # we calculate new std and mean
    masked_std = np.std(masked_array, axis=0)
    masked_mean = np.mean(masked_array, axis=0)

    # we mask based on mean +- 3 * stddev
    array_out = np.ma.MaskedArray(
                    arrayin,
                    mask = np.logical_or(
                    arrayin > masked_mean + masked_std * 3,
                    arrayin < masked_mean - masked_std * 3,
                    )
    )

    return array_out

# calculate multi-temporal metrics by looping throuch chunks defined by blocksize
def calc_mt_metrics(rasterfn, newRasterfn, metrics, cols, rows, x_block_size, y_block_size, data_type_name, outRaster, toPower, rescale_sar, outlier, ndv):

    raster3d = gdal.Open(rasterfn)

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
            stacked_array=np.empty((raster3d.RasterCount, ysize, xsize), dtype=data_type_name)

            # loop through the timeseries and fill the stacked array part
            for i in xrange( raster3d.RasterCount ):
                i += 0
                stacked_array[i,:,:] = np.array(raster3d.GetRasterBand(i+1).ReadAsArray(x,y,xsize,ysize))

            # original nd_mask
            nd_mask = stacked_array[1,:,:] == 0

            # rescale to db if data comes in compressed integer format
            if rescale_sar == 'yes' and data_type_name != 'Float32':
                stacked_array = rescale_from_int(stacked_array, data_type_name)

            # convert from dB to power
            if toPower == 'yes':
                stacked_array = convert_to_pow(stacked_array)

            # remove outliers
            if outlier == 'yes' and raster3d.RasterCount >= 5:
                stacked_array = outlier_removal(stacked_array)

            if 'avg' in metrics:
                # calulate the mean
                metric = np.mean(stacked_array, axis=0)

                # rescale to db
                if toPower == 'yes':
                    metric = convert_to_dB(metric)

                # rescale to actual data type
                if rescale_sar == 'yes' and data_type_name != 'Float32':
                    metric = rescale_to_int(metric,-30. ,5. , data_type_name)
                    metric[nd_mask == True] = ndv

                # write out to raster
                write_chunk_to_raster(newRasterfn + ".avg.tif", metric, ndv, x, y)

            if 'max' in metrics:
                # calulate the max
                metric = np.max(stacked_array, axis=0)

                # rescale to db
                if toPower == 'yes':
                    metric = convert_to_dB(metric)

                # rescale to actual data type
                if rescale_sar == 'yes' and data_type_name != 'Float32':
                    metric = rescale_to_int(metric,-30. ,5. , data_type_name)
                    metric[nd_mask == True] = ndv

                # write out to raster
                write_chunk_to_raster(newRasterfn + ".max.tif", metric, ndv, x, y)

            if 'min' in metrics:
                # calulate the max
                metric = np.min(stacked_array, axis=0)

                # rescale to db
                if toPower == 'yes':
                    metric = convert_to_dB(metric)

                # rescale to actual data type
                if rescale_sar == 'yes' and data_type_name != 'Float32':
                    metric = rescale_to_int(metric,-30. ,5. , data_type_name)
                    metric[nd_mask == True] = ndv

                # write out to raster
                write_chunk_to_raster(newRasterfn + ".min.tif", metric, ndv, x, y)

            if 'std' in metrics:
                # calulate the max
                metric = np.std(stacked_array, axis=0)

                # we do not rescale to dB for the standard deviation

                # rescale to actual data type
                if rescale_sar == 'yes' and data_type_name != 'Float32':
                    metric = rescale_to_int(metric, 0.000001, 0.5, data_type_name) + 1 # we add 1 to avoid no false no data values
                    metric[nd_mask == True] = ndv

                # write out to raster
                write_chunk_to_raster(newRasterfn + ".std.tif", metric, ndv, x, y)

            # Coefficient of Variation (aka amplitude dispersion)
            if 'cov' in metrics:
                # calulate the max
                metric = scipy.stats.variation(stacked_array, axis=0)

                # we do not rescale to dB for the CoV

                # rescale to actual data type
                if rescale_sar == 'yes' and data_type_name != 'Float32':
                    metric = rescale_to_int(metric, 0.001, 1. , data_type_name) + 1 # we add 1 to avoid no false no data values
                    metric[nd_mask == True] = ndv

                # write out to raster
                write_chunk_to_raster(newRasterfn + ".cov.tif", metric, ndv, x, y)

            # 90th percentile
            if 'p90' in metrics:
                # calulate the max
                metric = np.percentile(stacked_array, 90, axis=0)

                # rescale to db
                if toPower == 'yes':
                    metric = convert_to_dB(metric)

                # rescale to actual data type
                if rescale_sar == 'yes' and data_type_name != 'Float32':
                    metric = rescale_to_int(metric,-30. ,5. , data_type_name)
                    metric[nd_mask == True] = ndv

                # write out to raster
                write_chunk_to_raster(newRasterfn + ".p90.tif", metric, ndv, x, y)

            # 10th perentile
            if 'p10' in metrics:
                # calulate the max
                metric = np.percentile(stacked_array, 10, axis=0)

                # rescale to db
                if toPower == 'yes':
                    metric = convert_to_dB(metric)

                # rescale to actual data type
                if rescale_sar == 'yes' and data_type_name != 'Float32':
                    metric = rescale_to_int(metric,-30. ,5. , data_type_name)
                    metric[nd_mask == True] = ndv

                # write out to raster
                write_chunk_to_raster(newRasterfn + ".p10.tif", metric, ndv, x, y)

            # Difference between 90th and 10th percentile
            if 'pDiff' in metrics:
                # calulate the max
                metric = np.subtract(np.percentile(stacked_array, 90, axis=0), np.percentile(stacked_array, 10, axis=0))

                # rescale to actual data type
                if rescale_sar == 'yes' and data_type_name != 'Float32':
                    metric = rescale_to_int(metric, 0.001, 1. , data_type_name) + 1 # we add 1 to avoid no false no data values
                    metric[nd_mask == True] = ndv

                # write out to raster
                write_chunk_to_raster(newRasterfn + ".pDiff.tif", metric, ndv, x, y)

            # # Difference between 90th and 10th percentile
            if 'sum' in metrics:
                # calulate the max
                metric = np.sum(np.percentile(stacked_array, 90, axis=0), np.percentile(stacked_array, 10, axis=0))

                if rescale_sar == 'yes' and data_type_name != 'Float32':
                    # rescale to actual data type
                    metric = rescale_to_int(metric,-0.0001 ,1. , data_type_name)
                    metric[nd_mask == True] = ndv

                # write out to raster
                write_chunk_to_raster(newRasterfn + ".sum.tif", metric, ndv, x, y)

def run_all(rasterfn,newRasterfn,metrics,toPower,rescale_sar, outlier):

    # read the input raster and get the geo information
    geo_list = read_input_stack_geos(rasterfn)


    # we create our empty output files
    print " INFO: Creating output files."
    for metric in metrics:
        # create output rasters
        create_2d_raster(newRasterfn + "." + metric + ".tif", geo_list['cols'], geo_list['rows'], geo_list['dt'], geo_list['oX'],
                         geo_list['oY'], geo_list['pW'], geo_list['pH'], geo_list['outR'], geo_list['driver'], geo_list['ndv'])

    print " INFO: Calculating the multi-temporal metrics and write them to the respective output files."
    # calculate the multi temporal metrics by looping over blocksize
    calc_mt_metrics(rasterfn, newRasterfn, metrics, geo_list['cols'], geo_list['rows'], geo_list['xB'], geo_list['yB'], geo_list['dtn'],
                    geo_list['outR'], toPower, rescale_sar, outlier, geo_list['ndv'])


def main():

    from optparse import OptionParser

    usage = "usage: %prog [options] -i inputfile -o outputfile prefix -t type of metric -p toPower -m outlier removal"
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
                     "6 = Sum\t\t\t\t\t\t\t\t ",
                     #"7 = Min, SD ",
                metavar="<Number referring to MT metrics>")

    parser.add_option("-p", "--power", dest="toPower",
            help="de-logarithmize to power for computation", metavar="(yes/no) ")

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

    # create a vector of measures
    if options.mt_type is '1':
        metrics = ["avg", "max", "min", "std", "cov" ]
    elif options.mt_type is '2':
        metrics = [ "p90", "p10", "pDiff" ]
    elif options.mt_type is '3':
        metrics = [ "max", "min" ] # for extent
    elif options.mt_type is '4':
        metrics = [ "max" ] # for ls map
    elif options.mt_type is '5':
        metrics = ["avg", "max", "min", "std", "cov" , "skew", "kurt", "argmin", "argmax", "median" ]
    elif options.mt_type is '6':
        metrics = ["sum"] # for TRMM
    elif options.mt_type is '7':
        metrics = ["min","std"]

    run_all(options.ifile,options.ofile,metrics,options.toPower,options.rescale_sar,options.outlier)
    print 'time elapsed:', time() - currtime


if __name__ == "__main__":
    main()
