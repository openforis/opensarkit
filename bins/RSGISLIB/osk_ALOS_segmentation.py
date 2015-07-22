#! /home/avollrath/miniconda/bin/python

#conda install -c osgeo rsgis_scripts rsgislib kealib scikit-learn rios


import sys, getopt
import rsgislib
from rsgislib import imagecalc
from rsgislib import imageutils
from rsgislib.imagecalc import BandDefn


print 
# inputs 
#dem = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/DEM.kea'
#aspect = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/DEM_aspect.kea'
#slope = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/DEM_slope.kea'
Workspace = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/Outputs/'

inFileHH = (Workspace + 'Gamma0_HH.tif.kea')
inFileHV = (Workspace + 'Gamma0_HV.tif.kea')
inFileHHHV_ratio = (Workspace + 'HH_HV_ratio.tif.kea')
inFile_Mean_HH = (Workspace + 'GLCMMean_HH.tif.kea')
inFile_Mean_HV = (Workspace + 'GLCMMean_HV.tif.kea')
inFile_Var_HH = (Workspace + 'GLCMVariance_HH.tif.kea')
inFile_Var_HV = (Workspace + 'GLCMVariance_HV.tif.kea')

#	print inFileHH

# outputs
# HH/HV ratio
#outFileHHHV = (Workspace + 'ratio_rsgislib.kea')
outStackInt = (Workspace + 'stack.kea')
outStackInt_stretch= (Workspace + 'stack_stretch.tif')

# calculate ratio
#bandDefns = [imagecalc.BandDefn('hh', inFileHH, 1),
 #            imagecalc.BandDefn('hv', inFileHV, 1)]
#imagecalc.bandMath(outFileHHHV, 'hh/hv', 'KEA', rsgislib.TYPE_32FLOAT, bandDefns) 


# create image stack
bands_list = [inFileHH, inFileHV, inFileHHHV_ratio, inFile_Mean_HH, inFile_Mean_HV, inFile_Var_HH, inFile_Var_HV] #, dem, aspect, slope]
band_names = ['HH','HV', 'HH_HV', 'Mean_HH', 'Mean_HV', 'Var_HH', 'Var_HV']    #, 'dem', 'aspect', 'slope']
gdaltype = rsgislib.TYPE_32FLOAT
imageutils.stackImageBands(bands_list, band_names, outStackInt, None, 
                                    0, 'KEA', rsgislib.TYPE_32FLOAT) 

# stretch image
imageutils.stretchImage(outStackInt, outStackInt_stretch, False, '', True, False, 'GTiff', rsgislib.TYPE_8INT, imageutils.STRETCH_LINEARSTDDEV, 2)

#rsgislibsegmentation.py --input outStackInt --output '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/stack_clumps_elim_final_25.kea' --outmeanimg '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/stack_clumps_elim_final_mean_25.kea' -t /tmp --numclusters 15 --minpxls 25
#clumpsFile_100 = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/stack_clumps_elim_final_100.kea'
#meanImage_100 = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/PathMosaicTest/FINAL_MOSAIC/Seg/stack_clumps_elim_final_mean_100.kea'
#rsgislibsegmentation.py --input outStackInt --output Out_100	 --outmeanimg OutMean_100 -t /tmp --numclusters 100 --minpxls 100
#segutils.runShepherdSegmentation(outStackInt, clumpsFile_100,
#                    meanImage_100, numClusters=100, minPxls=100)
