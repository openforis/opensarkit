#! /usr/bin/python

# thanks to the great tutorial of Carlos de la Torre
# http://www.machinalis.com/blog/python-for-geospatial-data-processing/

import numpy as np
import os

from osgeo import gdal, ogr, osr
from sklearn import metrics
from sklearn.ensemble import RandomForestRegressor


def create_mask_from_vector(vlyr, cols, rows, geo_transform, projection, target_value=1,
                            output_fname='', dataset_format='MEM'):
    """
    Rasterize the given vector (wrapper for gdal.RasterizeLayer). Return a gdal.Dataset.
    :param vector_data_path: Path to a shapefile
    :param cols: Number of columns of the result
    :param rows: Number of rows of the result
    :param geo_transform: Returned value of gdal.Dataset.GetGeoTransform (coefficients for
                          transforming between pixel/line (P,L) raster space, and projection
                          coordinates (Xp,Yp) space.
    :param projection: Projection definition string (Returned by gdal.Dataset.GetProjectionRef)
    :param target_value: Pixel value for the pixels. Must be a valid gdal.GDT_UInt16 value.
    :param output_fname: If the dataset_format is GeoTIFF, this is the output file name
    :param dataset_format: The gdal.Dataset driver name. [default: MEM]
    """

    driver = gdal.GetDriverByName(dataset_format)
    target_ds = driver.Create(output_fname, cols, rows, 1, gdal.GDT_Float32)
    target_ds.SetGeoTransform(geo_transform)
    target_ds.SetProjection(projection)
    gdal.RasterizeLayer(target_ds, [1], vlyr, burn_values=[target_value])
    return target_ds

def write_geotiff(fname, data, geo_transform, projection, data_type=gdal.GDT_Float32):
    """
    Create a GeoTIFF file with the given data.
    :param fname: Path to a directory with shapefiles
    :param data: Number of rows of the result
    :param geo_transform: Returned value of gdal.Dataset.GetGeoTransform (coefficients for
                          transforming between pixel/line (P,L) raster space, and projection
                          coordinates (Xp,Yp) space.
    :param projection: Projection definition string (Returned by gdal.Dataset.GetProjectionRef)
    """
    driver = gdal.GetDriverByName('GTiff')
    rows, cols = data.shape
    dataset = driver.Create(fname, cols, rows, 1, data_type)
    dataset.SetGeoTransform(geo_transform)
    dataset.SetProjection(projection)
    band = dataset.GetRasterBand(1)
    band.WriteArray(data)

    # ct = gdal.ColorTable()
    # for pixel_value in range(len(classes)+1):
    #     color_hex = COLORS[pixel_value]
    #     r = int(color_hex[1:3], 16)
    #     g = int(color_hex[3:5], 16)
    #     b = int(color_hex[5:7], 16)
    #     ct.SetColorEntry(pixel_value, (r, g, b, 255))
    # band.SetColorTable(ct)

    # metadata = {
    #     'TIFFTAG_COPYRIGHT': 'CC BY 4.0',
    #     'TIFFTAG_DOCUMENTNAME': 'classification',
    #     'TIFFTAG_IMAGEDESCRIPTION': 'Supervised classification.',
    #     'TIFFTAG_MAXSAMPLEVALUE': str(len(classes)),
    #     'TIFFTAG_MINSAMPLEVALUE': '0',
    #     'TIFFTAG_SOFTWARE': 'Python, GDAL, scikit-learn'
    # }
    # dataset.SetMetadata(metadata)

    dataset = None  # Close the file
    return

def regressor(raster,vector,vfield,outfile):

    # 1 read raster file dimensions (not data for memory savage)
    # 2 read vector data and RasterizeLayer to a tmp data
    # 3 loop through blocks of both raster and rasterized training data
    # 4 create model
    # 5 output R^2, feature importance and confucion matrix, evtl. RMSE, and relative RMSE
    # 6 apply model to image data

    #-------------------------------------------------------------
    # 1) read raster file
    print "INFO: Reading raster file."

    try:
        raster_dataset = gdal.Open(raster, gdal.GA_ReadOnly)
    except RuntimeError as e:
        report_and_exit(str(e))

    cols = raster_dataset.RasterXSize
    rows = raster_dataset.RasterYSize
    n_bands = raster_dataset.RasterCount
    geo_transform = raster_dataset.GetGeoTransform()
    projection = raster_dataset.GetProjectionRef()

    # print out some infos
    print "Input file has: " + str(rows) + "rows and " + str(cols) + "columns"
    #-------------------------------------------------------------

    #-------------------------------------------------------------
    # Rasterizing vector
    print "INFO: Reading vector file."
    vector_data = ogr.Open(vector, gdal.GA_ReadOnly)
    layer = vector_data.GetLayer(0)
    ldefn = layer.GetLayerDefn()

    for i in range(ldefn.GetFieldCount()):
         if ldefn.GetFieldDefn(i).GetName() == vfield:
             fdefn = ldefn.GetFieldDefn(i)
             print fdefn.name
             n = i

    print layer.GetFeature().GetField(vfield)





    # bands_data = []
    # for b in range(1, raster_dataset.RasterCount+1):
    #     band = raster_dataset.GetRasterBand(b)
    #     bands_data.append(band.ReadAsArray())
    #
    # bands_data = np.dstack(bands_data)
    # rows, cols, n_bands = bands_data.shape
    #
    # print "Rows:" + str(rows)
    # print "Cols:" + str(cols)
    # print "Bands:" + str(n_bands)


    # read vector file and rasterize
    # vector_data = ogr.Open(vector, gdal.GA_ReadOnly)
    # layer = vector_data.GetLayer(0)
    # ldefn = layer.GetLayerDefn()
    #
    # for i in range(ldefn.GetFieldCount()):
    #         if ldefn.GetFieldDefn(i).GetName() == vfield:
    #                 fdefn = ldefn.GetFieldDefn(i)
    #
    # latlong = osr.SpatialReference()
    # latlong.ImportFromEPSG( 4326 )
    #
    # labeled_pixels = np.zeros((rows, cols))
    # feat = layer.GetNextFeature()
    #
    # while feat is not None:
    #
    #     if feat.GetField(vfield) is not None:
    #         label = feat.GetField(vfield)
    #         print label
    #
    #         #create a new layer
    #         # Invoke the GeoJSON driver
    #         drv = ogr.GetDriverByName( 'Memory' )
    #         # This is the output filename
    #         dst_ds = drv.CreateDataSource( 'out' )
    #         # This is a single layer dataset. The layer needs to be of points
    #         # and needs to have the WGS84 projection, which we defined above
    #         dst_layer = dst_ds.CreateLayer('', srs =latlong, geom_type=ogr.wkbPolygon )
    #
    #         dst_layer.CreateField(fdefn)
    #         dst_layer.CreateFeature(feat)
    #
    #         ds = create_mask_from_vector(dst_layer, cols, rows, geo_transform, projection,target_value=label)
    #         band = ds.GetRasterBand(1)
    #         a = band.ReadAsArray()
    #         labeled_pixels += a
    #     feat = layer.GetNextFeature()
    #     ds = None
    #     del ds
    #     dst_ds = None
    #     del dst_ds
    #
    # is_train = np.nonzero(labeled_pixels)
    # training_labels = labeled_pixels[is_train]
    # training_samples = bands_data[is_train]
    #
    # classifier = RandomForestRegressor(n_jobs=-1, n_estimators=10)
    # #logger.debug("Train the classifier: %s", str(classifier))
    # classifier.fit(training_samples, training_labels)
    # print "R^2:" + str(classifier.score(training_samples, training_labels))
    #
    # n_samples = rows*cols
    # print "here 1"
    # flat_pixels = bands_data.reshape((n_samples, n_bands))
    #
    # del bands_data
    # del training_samples
    # del training_labels
    #
    # print "here 2"
    # flat_pixels_subsets = np.array_split(flat_pixels, 25)
    # print "here 3"
    # results = []
    # for subset in flat_pixels_subsets:
    #     result_subset = classifier.predict(subset)
    #     results.append(result_subset)
    #
    # print "here 4"
    # result = np.concatenate(results)
    # print "here 5"
    # classification = result.reshape(cols, rows)
    # #logger.debug("Classifing...")
    # #result = classifier.predict(flat_pixels)
    # print "here 6"
    # # Reshape the result: split the labeled pixels into rows to create an image
    # #classification = result.reshape((rows, cols))
    # write_geotiff(outfile, classification, geo_transform, projection)
    # #logger.info("Classification created: %s", output_fname)

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
