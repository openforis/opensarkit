#! /home/avollrath/miniconda/bin/python

#conda install -c osgeo rsgis_scripts rsgislib kealib scikit-learn rios


import rsgislib
from rsgislib import imagecalc
from rsgislib import imageutils

# inputs 
inFileHH = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/Segmentation/08222_Gamma0_HH_db.kea'
inFileHV = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/Segmentation/08222_Gamma0_HV_db.kea'

print inFileHH

# outputs
# HH/HV ratio
outFileHHHV = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/Segmentation/out_hhhv_ratio.kea'
outStackInt = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/Segmentation/out_hhhv_ratio_stack.kea'
outStackInt_stretch = '/media/avollrath/phd_data2/FAO/Studies/Sri_Lanka/TEST/Segmentation/out_hhhv_ratio_stack_stretch.kea'

# calculate ratio
bandDefns = [imagecalc.BandDefn('hh', inFileHH, 1),
             imagecalc.BandDefn('hv', inFileHV, 1)]
imagecalc.bandMath(outFileHHHV, 'hh/hv', 'KEA', rsgislib.TYPE_32FLOAT, bandDefns) 


# create image stack
bands_list = [inFileHH, inFileHV, outFileHHHV]
band_names = ['HH','HV', 'HH/HV']
gdaltype = rsgislib.TYPE_32FLOAT
imageutils.stackImageBands(bands_list, band_names, outStackInt, None, 
                                    0, 'KEA', rsgislib.TYPE_32FLOAT) 

# stretch image
imageutils.stretchImage(outStackInt, outStackInt_stretch, False, '', True, False, 'GTiff', rsgislib.TYPE_8INT, imageutils.STRETCH_LINEARSTDDEV, 2)

rsgislibsegmentation.py --input out_hhhv_ratio_stack.kea --output out_hhhv_ratio_stack_clumps_elim_final.kea --outmeanimg out_hhhv_ratio_stack_clumps_elim_final_mean.kea -t /tmp --numclusters 100 --minpxls 100

