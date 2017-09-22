#! /usr/bin/python

# import packages
import gdal, ogr, osr, os
import numpy as np
from ost_io_ops import *
from optparse import OptionParser


def replaceValues(rasterfn,newRasterfn,repValue,newValue):

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

    outRaster = driver.Create(newRasterfn, cols, rows, 1, data_type,
        options=[           # Format-specific creation options.
        'BIGTIFF=IF_SAFER',
        'BLOCKXSIZE=' + str(cols),   # must be a power of 2
        'BLOCKYSIZE=1'    # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
        #'COMPRESS=LZW'
        #'TILED=YES'#,
        ] )
    outRaster.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
    outband = outRaster.GetRasterBand(1)
    outRaster.SetProjection(outRasterSRS.ExportToWkt())

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
            #stacked_array=np.empty((raster3d.RasterCount, ysize, xsize), dtype=data_type_name)
            rasterArray = np.array(band.ReadAsArray(x,y,xsize,ysize))
            rasterArray[rasterArray == np.float32(repValue)] = np.float32(newValue)

        outband.WriteArray(rasterArray, x, y)


    #print "Replacing all " + options.repValue + "'s' with " + options.newValue + "."
    # Convert Raster to array
    #rasterArray = raster2array(options.ifile)

    # Updata no data value in array with new value
    #rasterArray[rasterArray == np.fromstring(options.repValue, dtype=np.uint8)] = np.fromstring(options.newValue, dtype=np.uint8)


    # Write updated array to new raster
    #array2raster(options.ifile,options.ofile,rasterArray)

    # counter to write the outbup just once
    #k = k + 1

def main():
    usage = "usage: %prog [options] -i inputfile -o outputfile -rv value to replace -nv new value"
    parser = OptionParser()
    parser.add_option("-i", "--inputfile", dest="ifile",
                      help="write report to FILE", metavar="INPUTFILE")

    parser.add_option("-o", "--outputfile", dest="ofile",
                      help="write report to FILE", metavar="OUTPUTFILE")

    parser.add_option("-r", "--repValue", dest="repValue",
                      help="write report to FILE", metavar="REPVALUE")

    parser.add_option("-n", "--newValue", dest="newValue",
                      help="write report to FILE", metavar="NEWVALUE")

    parser.add_option("-q", "--quiet",
                      action="store_false", dest="verbose", default=True,
                      help="don't print status messages to stdout")

    (options, args) = parser.parse_args()

    if not options.ifile:
        parser.error("Inputfile is empty")
        print usage

    if not options.ofile:
        parser.error("Outputfile is empty")
        print usage

    if not options.repValue:
        parser.error("value ot replace is empty")
        print usage

    if not options.newValue:
        parser.error("new value is empty")
        print usage

    replaceValues(options.ifile, options.ofile, options.repValue, options.newValue)

if __name__ == "__main__":
   main()
