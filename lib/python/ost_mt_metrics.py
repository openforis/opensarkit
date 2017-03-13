#! /usr/bin/python

# import packages
import gdal, ogr, osr, os
import numpy as np
import numpy.ma as ma
import scipy
from scipy import stats
from time import time

def mt_metrics(rasterfn,newRasterfn):

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

    # we need this for file creation
    outRasterSRS = osr.SpatialReference()
    outRasterSRS.ImportFromWkt(raster3d.GetProjectionRef())

    # we will need this to create the output just once
    k = 1


    # loop through y direction
    for y in range(0, rows, y_block_size):
        if y + y_block_size < rows:
            ysize = y_block_size
        else:
            ysize = rows - y

        # loop throug x direction
        for x in range(0, cols, x_block_size):
            if x + x_block_size < cols:
                xsize = x_block_size
            else:
                xsize = cols - x

            # create the blocksized array
            stacked_array=np.empty((raster3d.RasterCount, ysize, xsize), dtype=data_type_name) # change fixed uint16 with numpy datatype

            # loop through the timeseries and fill the stacked array part
            for i in range( raster3d.RasterCount ):
                i += 0
                stacked_array[i,:,:] = np.array(raster3d.GetRasterBand(i+1).ReadAsArray(x,y,xsize,ysize))
                #mask = np.greater(0, stacked_array)
                #masked_stack = ma.masked_array(stacked_array, mask)

                # loop through the metrics
            # create a vector of measures
            metrics = ["avg", "max", "min", "std", "cov" ]
            #metrics = ["mean", "maximum", "minimum", "stddev", "cov" , "skewness", "kurtosis", "argmin", "argmax", "median", "nth moment"]

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

                    outmetric = np.mean(stacked_array, axis=0)
                    outband_avg.WriteArray(outmetric, x, y)

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

                    outmetric = np.max(stacked_array, axis=0)
                    outband_max.WriteArray(outmetric, x, y)

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

                    outmetric = np.min(stacked_array, axis=0)
                    outband_min.WriteArray(outmetric, x, y)

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

                    outmetric = np.std(stacked_array, axis=0)
                    outband_std.WriteArray(outmetric, x, y)

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

                    outmetric = scipy.stats.variation(stacked_array, axis=0)
                    outband_cov.WriteArray(outmetric, x, y)

            # counter to write the outbup just once
            k = k + 1

def main():

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
    mt_metrics(options.ifile,options.ofile)
    print 'time elapsed:', time() - currtime


if __name__ == "__main__":
    main()
