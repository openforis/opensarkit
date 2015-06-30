#! /usr/bin/python

from osgeo import gdal
import sys
import numpy
src_file = sys.argv[1]
dst_file = sys.argv[2]
out_bands = 1

# Open source file

# dataset
src_ds = gdal.Open( src_file )
cols = src_ds.RasterXSize
rows = src_ds.RasterYSize
bands = src_ds.RasterCount
driver = src_ds.GetDriver()
driver_short= src_ds.GetDriver().ShortName
driver_long = src_ds.GetDriver().LongName

# band
src_band = src_ds.GetRasterBand(1)

# extent for other formats
#bandtype = gdal.GetDataTypeName(src_band.DataType)

# do the byteswap
data = src_band.ReadAsArray(0, 0, cols, rows)
dst_band = data.byteswap(True)
dst_band.astype('float32').tofile(dst_file)


