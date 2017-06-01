#! /usr/bin/python

# import packages
import gdal, ogr, osr, os
import numpy as np
from time import time


def rmv_brd(rasterfn,newRasterfn):

    # open raster file
    raster = gdal.Open(rasterfn)

    # Get blocksizes for iterating over tiles (chuuks)
    myBlockSize=raster.GetRasterBand(1).GetBlockSize();
    x_block_size = myBlockSize[0]
    y_block_size = myBlockSize[1]

    # Get image sizes
    cols = raster.RasterXSize
    rows = raster.RasterYSize

    # get datatype and transform to numpy readable
    data_type = raster.GetRasterBand(1).DataType
    data_type_name = gdal.GetDataTypeName(data_type)
    driver = raster.GetDriver() #.ShortName

    band=raster.GetRasterBand(1)
    geotransform = raster.GetGeoTransform()
    originX = geotransform[0]
    originY = geotransform[3]
    pixelWidth = geotransform[1]
    pixelHeight = geotransform[5]
    ndv = raster.GetRasterBand(1).GetNoDataValue()

    # we need this for file creation
    outRasterSRS = osr.SpatialReference()
    outRasterSRS.ImportFromWkt(raster.GetProjectionRef())

    # create output file
    outRaster = driver.Create(newRasterfn, cols, rows, 1, data_type)
    outRaster.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
    outband = outRaster.GetRasterBand(1)
    outRaster.SetProjection(outRasterSRS.ExportToWkt())

    # create line array
    array_left = np.array(raster.GetRasterBand(1).ReadAsArray(0,0,3000,rows))

    currtime = time()
    # loop through the first 2000 rows
    for x in xrange(3000):
        # condition if more than 50 pixels within the line have values less than 500, delete the line
        #if np.sum(np.where((array_left[:,x] < 200) & (array_left[:,x] > 0) , 1, 0)) <= 50:
        if np.mean(array_left[:,x]) <= 100:
            array_left[:,x].fill(0)
        else:
            z = x + 150
            if z > 3000:
               z = 3000
            for y in xrange(x,z,1):
                array_left[:,y].fill(0)

            cols_left = y
            break

    try:
        cols_left
    except NameError:
        cols_left = 3000

    # write array_left to disk
    print "Colums total:", cols
    print "Colums cut left side:", cols_left
    outband.WriteArray(array_left[:,:+cols_left].byteswap(True), 0, 0)
    array_left = None


    # get the 2000th latest col number and get array_right
    cols_last = cols - 3000
    array_right = np.array(raster.GetRasterBand(1).ReadAsArray(cols_last,0,3000,rows))

    # loop through the array_right colums
    for x in xrange(2999, 0, -1):
         # condition if more than 50 pixels within the line have values less than 500, delete the line
         #if np.sum(np.where((array_right[:,x] < 200) & (array_right[:,x] > 0), 1, 0)) >= 50:
         if np.mean(array_right[:,x]) <= 100:
             array_right[:,x].fill(0)
         else:
             z = x - 150
             if z < 0:
                z = 0
             for y in xrange(x,z,-1):
                 array_right[:,y].fill(0)

             cols_right = y
             break

    try:
        cols_right
    except NameError:
        cols_right = 0


    col_right_start = cols - 3000 + cols_right
    print "Colums cut right side:", 3000 - cols_right
    print "Amount of columns kept:", col_right_start
    outband.WriteArray(array_right[:,cols_right:].byteswap(True), col_right_start , 0)
    array_right = None

    # range for intermediate data
    print "Write valid columns of image to disk"
    cols_middle = cols - ( cols_left + (3000 - cols_right) )
    middle_array = raster.GetRasterBand(1).ReadAsArray(cols_left,0,cols_middle,rows)
    outband.WriteArray(middle_array.byteswap(True), cols_left, 0)
    middle_array = None

def main():

    from optparse import OptionParser

    usage = "usage: %prog [options] -i inputfile -o outputfile prefix -t type of metric"
    parser = OptionParser()
    parser.add_option("-i", "--inputfile", dest="ifile",
                help="choose an input time-series stack", metavar="<input time-series stack>")

    parser.add_option("-o", "--outputfile", dest="ofile",
                help="Outputfile prefix ", metavar="<utputfile prefix>")

    (options, args) = parser.parse_args()

    if not options.ifile:
        parser.error("Inputfile is empty")
        print usage

    if not options.ofile:
        parser.error("Outputfile is empty")
        print usage

    currtime = time()
    rmv_brd(options.ifile,options.ofile)
    print 'time elapsed:', time() - currtime


if __name__ == "__main__":
    main()
