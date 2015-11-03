#Size Functions
#This size function echos the pixel dimensions of a given file in the format expected by gdalwarp.

function gdal_size() {
    SIZE=$(gdalinfo $1 |\
        grep 'Size is ' |\
        cut -d\   -f3-4 |\
        sed 's/,//g')
    echo -n "$SIZE"
}

#This can be used to easily resample one raster to the dimensions of another:
#gdalwarp -ts $(gdal_size bigraster.tif) -r cubicspline smallraster.tif resampled_smallraster.tif


# Extent Functions
# These extent functions echo the extent of the given file in the order/format expected by gdal_translate -projwin. (Originally from Linfiniti).
# Extents can be passed directly into a gdal_translate command like so:

# gdal_translate -projwin $(ogr_extent boundingbox.shp) input.tif clipped_output.tif
# or
# gdal_translate -projwin $(gdal_extent target_crop.tif) input.tif clipped_output.tif
# This can be a useful way to quickly crop one raster to the same extent as another. 
# Add these to your ~/.bash_profile file for easy terminal access.

function gdal_extent() {
    if [ -z "$1" ]; then 
        echo "Missing arguments. Syntax:"
        echo "  gdal_extent <input_raster>"
        return
    fi
    EXTENT=$(gdalinfo $1 |\
        grep "Upper Left\|Lower Right" |\
        sed "s/Upper Left  //g;s/Lower Right //g;s/).*//g" |\
        tr "\n" " " |\
        sed 's/ *$//g' |\
        tr -d "[(,]")
    echo -n "$EXTENT"
}

function ogr_extent() {
    if [ -z "$1" ]; then 
        echo "Missing arguments. Syntax:"
        echo "  ogr_extent <input_vector>"
        return
    fi
    EXTENT=$(ogrinfo -al -so $1 |\
        grep Extent |\
        sed 's/Extent: //g' |\
        sed 's/(//g' |\
        sed 's/)//g' |\
        sed 's/ - /, /g')
    EXTENT=`echo $EXTENT | awk -F ',' '{print $1 " " $4 " " $3 " " $2}'`
    echo -n "$EXTENT"
}

function ogr_layer_extent() {
    if [ -z "$2" ]; then 
        echo "Missing arguments. Syntax:"
        echo "  ogr_extent <input_vector> <layer_name>"
        return
    fi
    EXTENT=$(ogrinfo -so $1 $2 |\
        grep Extent |\
        sed 's/Extent: //g' |\
        sed 's/(//g' |\
        sed 's/)//g' |\
        sed 's/ - /, /g')
    EXTENT=`echo $EXTENT | awk -F ',' '{print $1 " " $4 " " $3 " " $2}'`
    echo -n "$EXTENT"
}

function gdal_max() {
    if [ -z "$1" ]; then 
        echo "Missing arguments. Syntax:"
        echo "  gdal_max <input_raster>"
        return
    fi
    MAX=$(gdalinfo -stats $1 |\
	grep STATISTICS_MAXIMUM |\
        awk -F "=" $'{print $2}')
    echo -n "$MAX"
}

function gdal_min() {
    if [ -z "$1" ]; then 
        echo "Missing arguments. Syntax:"
        echo "  gdal_max <input_raster>"
        return
    fi
    MIN=$(gdalinfo -stats $1 |\
	grep STATISTICS_MINIMUM |\
        awk -F "=" $'{print $2}')
    echo -n "$MIN"
}

function gdal_mean() {
    if [ -z "$1" ]; then 
        echo "Missing arguments. Syntax:"
        echo "  gdal_max <input_raster>"
        return
    fi
    MEAN=$(gdalinfo -stats $1 |\
	grep STATISTICS_MEAN |\
        awk -F "=" $'{print $2}')
    echo -n "$MEAN"
}

function gdal_stddev() {
    if [ -z "$1" ]; then 
        echo "Missing arguments. Syntax:"
        echo "  gdal_max <input_raster>"
        return
    fi
    STDDEV=$(gdalinfo -stats $1 |\
	grep STATISTICS_STDDEV |\
        awk -F "=" $'{print $2}')
    echo -n "$STDDEV"
}

