#! /usr/bin/python

# import packages
import gdal, ogr, osr, os
import rasterio
import numpy as np
import sys
#----------------------------------------
# Input functions
#----------------------------------------

# import raster to array
def raster2array(rasterfn):
    raster = gdal.Open(rasterfn)
    band = raster.GetRasterBand(1)
    return band.ReadAsArray()

# import raster to array
def raster3D2array3D(rasterfn):
    raster3d = gdal.Open(rasterfn)
    if raster3d is None:
        print 'Unable to open input file'
        sys.exit(1)

    band = raster3d.GetRasterBand(1)
    cols = raster3d.RasterXSize
    rows = raster3d.RasterYSize
    #data_type = raster3d.GetRasterBand(1).DataType
    data_type_name = gdal.GetDataTypeName(raster3d.GetRasterBand(1).DataType)
    if data_type_name == "Byte":
        data_type_name = "uint8"

    NDV = raster3d.GetRasterBand(1).GetNoDataValue()
    #print NDV

    stacked_array=np.empty((raster3d.RasterCount, rows, cols), dtype=data_type_name) # change fixed uint16 with numpy datatype

    print " INFO: Importing", raster3d.RasterCount, "bands from", rasterfn
    for i in range( raster3d.RasterCount ):
        i += 0
        print " INFO: Loading Band: ", i+1
        stacked_array[i,:,:] = np.array(raster3d.GetRasterBand(i+1).ReadAsArray()) # 1-based index
        #stacked_array[stacked_array == 0] = np.nan

    return stacked_array

def rasterio2array(rasterfn):
    with rasterio.open(rasterfn) as raster:
        arr = raster.read()

    return arr

#----------------------------------------
# Output functions
#----------------------------------------
# output array to raster
def array2raster(rasterfn,newRasterfn,array):
    raster = gdal.Open(rasterfn)
    geotransform = raster.GetGeoTransform()
    originX = geotransform[0]
    originY = geotransform[3]
    pixelWidth = geotransform[1]
    pixelHeight = geotransform[5]
    cols = raster.RasterXSize
    rows = raster.RasterYSize

    driver = gdal.GetDriverByName('GTiff')
    data_type = raster.GetRasterBand(1).DataType
    outRaster = driver.Create(newRasterfn, cols, rows, 1, data_type,
        options=[           # Format-specific creation options.
        'TILED=YES',
        'BIGTIFF=IF_SAFER',
        'BLOCKXSIZE=256',   # must be a power of 2
        'BLOCKYSIZE=256'    # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
        ] )
    outRaster.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
    outband = outRaster.GetRasterBand(1)
    outband.WriteArray(array)
    outRasterSRS = osr.SpatialReference()
    outRasterSRS.ImportFromWkt(raster.GetProjectionRef())
    outRaster.SetProjection(outRasterSRS.ExportToWkt())
    outband.FlushCache()

def array2FLTraster(rasterfn,newRasterfn,array):
    raster = gdal.Open(rasterfn)
    geotransform = raster.GetGeoTransform()
    originX = geotransform[0]
    originY = geotransform[3]
    pixelWidth = geotransform[1]
    pixelHeight = geotransform[5]
    cols = raster.RasterXSize
    rows = raster.RasterYSize

    driver = gdal.GetDriverByName('GTiff')
    data_type = raster.GetRasterBand(1).DataType
    outRaster = driver.Create(newRasterfn, cols, rows, 1, gdal.GDT_Float32,
        options=[           # Format-specific creation options.
        'TILED=YES',
        'BIGTIFF=IF_SAFER',
        'BLOCKXSIZE=256',   # must be a power of 2
        'BLOCKYSIZE=256'    # also power of 2, need not match BLOCKXSIZEBLOCKXSIZE
        ] )
    outRaster.SetGeoTransform((originX, pixelWidth, 0, originY, 0, pixelHeight))
    outband = outRaster.GetRasterBand(1)
    outband.WriteArray(array)
    outRasterSRS = osr.SpatialReference()
    outRasterSRS.ImportFromWkt(raster.GetProjectionRef())
    outRaster.SetProjection(outRasterSRS.ExportToWkt())
    outband.FlushCache()
