# Open SAR Toolkit (OST) - automated processing routines for wide-area land applications

## Objective 

Compared to its optical counterpart, the community of Synthetic Aperture Radar (SAR) data users for land applications is still small. One major reason for that originates from the differences in the acquisition principle and the underlying physics of the imaging process. For non-experts, this results in difficulties of applying the correct processing steps as well as interpreting the non-intuitive backscatter image composites. On the other hand, the free and open access to Sentinel-1 data widened the community of interested users and paves the way for the integration of SAR data into operational monitoring systems.

In order to ease the use and access to analysis-ready SAR data for wide-area land applications, the Food and Agriculture Organization of the United Nations develops the Open SAR Toolkit (OST) under the SEPAL project. OST includes fully automated pre-processing routines that are mainly build on top of the Sentinel Application Platform (SNAP) and other freely available open-source software such as GDAL, Orfeo Toolbox and Python. The simple and intuitive GUI is based on the R Shiny package and is accessed via a web-browser. This allows to employ OST also on cloud-platforms, as in the case of SEPAL.

## Functionality

For the moment, supported data sets are the ALOS Kyoto & Carbon mosaics and Sentinel-1 GRD products. The former are freely available for non-commercial use, and OST eases the access and preparation of the data tiles provided by JAXA (user account is necessary). For Sentinel-1, data inventory and download routines, as well as a GRD to RTC processor allows for the rapid generation of radiometrically terrain corrected (RTC) imagery that is ready for subsequent analysis tasks such as land cover classification. More advanced and processing intensive data products, such as time-series and timescan imagery can be easily produced as well in a fully automatic manner. Ultimately, mosaicking generates seamless wide-area data sets. Alongside the processing routines, accompanying demos and capacity building material provide the user a gentle entry into the world of radar remote sensing for land applications and refer to a wealth of relevant literatureand websites for a more profound study of the subject.

## Installation

OST is developed and tested on Ubuntu 16.04. An installer is available. 
It can be downlaoded and executed as sudo user (you need an admin password) on the command line by typing:
```
wget https://raw.githubusercontent.com/openforis/opensarkit/master/bins/Install_OFST/installer_ubuntu1604.sh
sudo bash installer_ubuntu1604.sh
```
After the installation successfully finished, restart the computer and launch OST via the newly desktop icon present. 

While most of the fucntionality runs on older machines (i.e. 4GB RAM and more), Sentinel-1 processing is quite resource intensive and needs at least 16 GB of RAM. 
