#! /usr/bin/python

# thanks to the great tutorial of Carlos de la Torre
# http://www.machinalis.com/blog/python-for-geospatial-data-processing/

import numpy as np
import os
from osgeo import gdal, ogr, osr
from sklearn import metrics
from sklearn.ensemble import RandomForestRegressor

# Tell GDAL to throw Python exceptions, and register all drivers
gdal.UseExceptions()
gdal.AllRegister()



def regressor(raster, vector, field, ofile):

    print("------------------------------------------------------")
    print("INFO: Opening the vector file")
    # Open the vector dataset from the file
    vds = ogr.Open(vector)
    # Make sure the dataset exists -- it would be None if we couldn't open it
    if not vds:
        print('ERROR: could not open vector dataset. File does not exit.')
        exit()
    ### Let's get the driver from this file
    vdriver = vds.GetDriver()
    ### How many layers are contained in this Shapefile?
    layer_count = vds.GetLayerCount()

    ### What is the name of the 1 layer?
    layer = vds.GetLayerByIndex(0)

    ### What is the layer's geometry? is it a point? a polyline? a polygon?
    # First read in the geometry - but this is the enumerated type's value
    geometry = layer.GetGeomType()

    # So we need to translate it to the name of the enum
    geometry_name = ogr.GeometryTypeToName(geometry)

    if geometry_name != 'Polygon':
        print("ERROR: Shapefile is not a polygon layer.")
        exit()

    ### What is the layer's projection?
    # Get the spatial reference
    spatial_ref = layer.GetSpatialRef()
    # Export this spatial reference to something we can read... like the Proj4
    proj4 = spatial_ref.ExportToProj4()
    epsg = spatial_ref.GetAttrValue("GEOGCS|AUTHORITY", 1)
    ### How many features are in the layer?
    feature_count = layer.GetFeatureCount()
    print('INFO: Layer has {n} features'.format(n=feature_count))

    ### How many fields are in the shapefile, and what are their names?
    # First we need to capture the layer definition
    defn = layer.GetLayerDefn()

    # How many fields
    field_count = defn.GetFieldCount()

    # What are their names?

    print('INFO: Dataset driver is {n}'.format(n=vdriver.name))
    print('INFO: The shapefile has {n} layer(s)'.format(n=layer_count))
    print('INFO: The layer is named: {n}'.format(n=layer.GetName()))
    print("INFO: The layer's geometry is: {geom}".format(geom=geometry_name))
    print('INFO: Layer projection is EPSG: {epsg}'.format(epsg=epsg))
    print('INFO: Layer has {n} fields'.format(n=field_count))
    print('INFO: Field names are: ')
    for i in range(field_count):
        field_defn = defn.GetFieldDefn(i)
        print('\t{name} - {datatype}'.format(name=field_defn.GetName(), datatype=field_defn.GetTypeName()))

        if field_defn.GetName() == field:
            j = 1

    # throw an error if field name is not available
    if j != 1:
        print('ERROR: No field named {f}'.format(f=field))
        exit()
    print("------------------------------------------------------\n")


    print("------------------------------------------------------")
    print "INFO: Opening raster file."
    # Open the vector dataset from the file
    rds = gdal.Open(raster)
    # Make sure the dataset exists -- it would be None if we couldn't open it
    if not rds:
        print('ERROR: could not open raster dataset. File does not exist.')
        exit()

    cols = rds.RasterXSize
    rows = rds.RasterYSize
    bands = rds.RasterCount
    geo_transform = rds.GetGeoTransform()
    rprojection = rds.GetProjectionRef()
    rsrs=osr.SpatialReference(wkt=rprojection)

    # print out some infos
    print "INFO: Input raster file has " + str(rows) + " rows and " + str(cols) + " columns."
    print "INFO: Input raster file has " + str(bands) + " bands."
    print "INFO: Input raster projection is EPSG: " + rsrs.GetAttrValue('GEOGCS|AUTHORITY', 1)
    print("------------------------------------------------------\n")


    print("------------------------------------------------------")
    print("INFO: Rasterizing the training data.")
    ###Rasterize training data
    # Create the raster dataset
    ras_driver = gdal.GetDriverByName('GTiff')
    out_raster_ds = ras_driver.Create(ofile, cols, rows, 1, gdal.GDT_Float32)

    # Set the ROI image's projection and extent to our input raster's projection and extent
    out_raster_ds.SetProjection(rprojection)
    out_raster_ds.SetGeoTransform(geo_transform)

    # Fill our output band with the 0 blank, no class label, value
    b = out_raster_ds.GetRasterBand(1)
    b.Fill(0)

    # Rasterize the shapefile layer to our new dataset
    status = gdal.RasterizeLayer(out_raster_ds,  # output to our new dataset
                             [1],  # output to our new dataset's first band
                             layer,  # rasterize this layer
                             options = ['ALL_TOUCHED=FALSE',  # rasterize all pixels touched by polygons
                              "ATTRIBUTE=%s" % field]  # put raster values according to the 'id' field values
                             )

    # Close dataset
    out_raster_ds = None

    if status != 0:
        print("Rasterize of training data failed")
        exit()
    else:
        print("Successfully rasterized the training data.")


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
                help="Outputfile prefix ", metavar="<outputfile prefix>")

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
    print options.ofile
    regressor(options.iraster,options.ivector,options.vfield,options.ofile)
    print 'time elapsed:', time() - currtime


if __name__ == "__main__":
    main()
