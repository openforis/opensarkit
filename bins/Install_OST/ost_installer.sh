#!/bin/bash

# The MIT License (MIT)
# Copyright (c) 2016 Andreas Vollrath

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

OST_VERSION="0.1-alpha.1"

if [ "$#" == "2" ];then

	echo -e ""
	echo -e "----------------------------------"
	echo -e " Open SAR Toolkit, version ${OSK_VERSION}"
	echo -e " Install script"
	echo -e "----------------------------------"
	echo -e ""

	export OST_HOME=$(readlink -f $1)

else

	echo -e ""
	echo -e "----------------------------------"
	echo -e " Open SAR Toolkit, version ${OSK_VERSION}"
	echo -e " Install script"
	echo -e "----------------------------------"
	echo -e ""

	echo -e " Usage: install_ost <install dir> <dependencies> <output resolution>" # <elevation> "
	echo -e ""
	echo -e " input parameters:"
	echo -e "  install dir		(input) path to OST installation"
	echo -e "  dependencies: "
	echo -e "			  Available choices:"
	echo -e "			  0: install without dependencies "
	echo -e "			  1: install dependencies and set up environmental variables"
	echo -e "			  "
	echo -e ""
	exit 1

fi

mkdir -p ${OST_HOME}
mkdir -p ${OST_HOME}/LOG
OPENSARKIT=${OST_HOME}

# get OST tagged version from github
SECONDS=0
echo -ne " Getting the Open SAR Toolkit ..." &&
wget https://github.com/openforis/opensarkit/archive/v0.1-alpha.1.tar.gz
tar -xzf v0.1-alpha.1.tar.gz
mv opensarkit-0.1-alpha.1/* ${OST_HOME}
rm -rf opensarkit-0.1-alpha.1 v0.1-alpha.1.tar.gz
echo "OPENSARKIT=${OST_HOME}" | tee -a /etc/environment
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"


OST_VERSION=0.1-alpha.1

cd ${OST_HOME}/bins

BINDIR=/usr/local/bin/

for OST_BINS in `ls -1 -d */`;do

	cd $OST_BINS
	for exe in `ls -1 {ost_*,post_*} 2>/dev/null`;do

		exepath=`readlink -f $exe`
		ln -s $exepath ${BINDIR}/

	done

	cd ../
done

#------------------------------------------------------------------
# Download the OST Database
#------------------------------------------------------------------

mkdir -p ${OST_HOME}/Database
cd ${OST_HOME}/Database

SECONDS=0
echo -ne " Downloading the OST database ..."
echo "OST_DB=${OST_HOME}/Database/OST_db.sqlite" | tee -a /etc/environment
wget https://www.dropbox.com/s/qvujm3l0ba0frch/OFST_db.sqlite?dl=0  >> ${OST_HOME}/LOG/log_install 2>&1
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"
mv OFST_db.sqlite?dl=0 OST_db.sqlite

#------------------------------------------------------------------
# Create a start-up icon
#------------------------------------------------------------------
echo -ne " Creating a start up icon on the Desktop ..."
echo "[Desktop Entry]" > ${HOME}/Desktop/OST.desktop
echo "Version=0.1-alpha.1" >> ${HOME}/Desktop/OST.desktop
echo "Name=Open SAR Toolkit" >> ${HOME}/Desktop/OST.desktop
echo "Comment=" >> ${HOME}/Desktop/OST.desktop
echo 'Exec=bash -c "R CMD BATCH ${OST_HOME}/shiny/ost.R;$SHELL"' >> ${HOME}/Desktop/OST.desktop
echo "Icon=${OST_HOME}/OST_icon_trans.png" >> ${HOME}/Desktop/OST.desktop
echo "Terminal=true" >> ${HOME}/Desktop/OST.desktop
echo "Type=Application" >> ${HOME}/Desktop/OST.desktop
echo "Categories=Education;" >> ${HOME}/Desktop/OST.desktop
echo "Path=" >> ${HOME}/Desktop/OST.desktop
echo "StartupNotify=false" >> ${HOME}/Desktop/OST.desktop

echo "require(shiny)" > ${OST_HOME}/shiny/ost.R
echo "runApp('${OPENSARKIT}/shiny/',launch.browser = T)" >> ${OST_HOME}/shiny/ost.R

chmod +x ${HOME}/Desktop/OST.desktop
chown ${HOME_USER}:${HOME_USER} ${HOME}/Desktop/OST.desktop

mv ${HOME}/Desktop/OST.desktop /usr/share/applications/OST.desktop
rm -f ${HOME}/Desktop/OST.desktop
duration=$SECONDS && echo -e " done ($(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed)"

if [[ $2 == 1 ]];then
	bash $OST_HOME/bins/Install_OST/ost_dependencies_ubuntu1604.sh
fi

echo "---------------------------------------------------------------------------------------------------------------------------"
echo " Installation of OST succesfully completed"
echo " In order to be able to launch the scripts immediately on the command line, type: source /etc/environment "
echo " Otherwise restart your computer"
echo "---------------------------------------------------------------------------------------------------------------------------"
