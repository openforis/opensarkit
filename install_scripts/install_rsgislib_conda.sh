#! /bin/bash


wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh

bash Miniconda3-latest-Linux-x86_64.sh

cd ${HOME}/miniconda3
conda install -c osgeo rsgislib
conda install -c rsgislib rios tuiview scikit-learn
