# Fast Sentinel-1/2 batch data download and pre-processing

## Description

Toolbox for downloading and pre-processing (atmospheric correction, mosaicing, etc.) cloud-free seasonal Sentinel-2 and Sentinel-1 data of a list of ROIs.

Developed for and tested on Linux systems only.

## Prerequisites

- **Valid login credentials for DHuS** at both of the following:
  - Copernicus Open Access Hub: https://scihub.copernicus.eu/dhus/#/self-registration
  - CODE-DE site: https://code-de.org/dhus/#/self-registration
- **code-de-tools** (available on [this GitHub site](https://github.com/dlr-eoc/code-de-tools))
- anconda3
- perl
- **gdal** (version >= 2.3.1; use standard system installation procedure or download from [www.gdal.org](https://www.gdal.org/))
- **sen2cor** (Sentinle-2 atmospheric correction: generates Level 2A from Level 1C products)
    - download standalone installer ```Sen2Cor-XX.XX.XX-Linux64.run``` of the latest release (version >= 2.5.5) from the [official ESA sen2cor
  website](http://step.esa.int/main/third-party-plugins-2/sen2cor/) into a suitable directory ```<path_to_sen2cor_dir>```.
    - install via ```cd <path_to_sen2cor_dir> && chmod +x Sen2Cor-XX.XX.XX-Linux64.run && ./Sen2Cor-XX.XX.XX-Linux64.run```
    - The L2A processor can be called with ```<path_to_sen2cor_dir>/Sen2Cor-XX.XX.XX-Linux64/bin/L2A_Process
      <path_to_Sentinel2_L1C_product_dir.SAFE>``` (further described below)
    
- **ROIs** (list of rectangular regions of interest (ROIs) each of which is defined in latitude and longitude degrees
  as further described below)
- **Sentinel-2 tiling grid** (available as kml file on the [ESA Sentinel-2 website](https://sentinel.esa.int/documents/247904/1955685/S2A_OPER_GIP_TILPAR_MPC__20151209T095117_V20150622T000000_21000101T000000_B00.kml))

- **Python-related**
  - python (version >= 3.6)
  - argparse
  - numpy
  - pandas
  - gdal (version >= 2.3.1)
  - imageio
  - multiprocessing
  - time
  - pip3
  
- **linux-related**
  - perl
  - wget
  - curl

## Authentification
For each data download from Code-DE or Copernicus-SciHub, your credentials (user name and password) corresponding to the respective account must be provided. One way of doing so, which is the way recommended to be used with this toolbox, is to save those credentials in a ```~/.netrc``` file stored in your home directory. This file must contain the following lines:
```
machine scihub.copernicus.eu
    login your-scihub-username
    password your-scihub-password

machine sso.eoc.dlr.de
    login your-code-de-username
    password your-code-de-password

```
Make sure only you have read/write access. Such permissions can be set via ```chmod 600 ~/.netrc```.

## Getting started
*to be done*

## ROIs
A csv file named ROIs.csv must be provided which contains a list of rectangular regions of interest (ROIs). Each line must be formated as follows:

```<scene_name>```**,**```<lon_UL>```**,**```<lat_UL>```**,**```<lon_LR>```**,**```<lat_LR>```

where \
   ```scene_name```= arbitrary scene name of your choice,\
   ```lon```= "longitude coordinate in degrees",\
   ```lat```= "latitude coordinate in degrees",\
   ```UL```= "upper left corner", and\
   ```LR```= "lower right corner".

#### Example
The content of an ROIs.csv file should look as follows:
```
   LCZ42_20272_riodejaneiro,-44.007655,-22.638080,-43.021185,-23.100297
   LCZ42_20287_saopaulo,-46.949171,-23.350688,-46.083863,-23.863944
   LCZ42_20382_London,-0.890974,51.812405,0.929674,51.090574
   LCZ42_204296_Berlin,12.913527,52.831532,13.893830,52.281907
   LCZ42_204358_Cologne,6.514675,51.271991,7.419368,50.641988
   LCZ42_204371_Munich,11.123657,48.492369,11.982177,47.731852
   LCZ42_20439_santiago,-70.965911,-33.207094,-70.416247,-33.712394
   LCZ42_20464_Beijing,115.704972,40.574582,117.079082,39.624091
   LCZ42_20474_Changsha,112.672191,28.413644,113.300063,28.041763
   LCZ42_206167_Sydney,150.570935,-33.583941,151.357933,-34.009008
   LCZ42_20625_Nanjing,118.466716,32.442510,119.187499,31.716857
   LCZ42_20641_Qingdao,119.916088,36.474838,120.792555,35.823668
   LCZ42_20656_Shanghai,121.080843,31.532435,122.007591,30.837441
   LCZ42_20712_Wuhan,113.943027,30.927563,114.874441,30.210727
   LCZ42_20985_Paris,1.561616,49.282085,2.933627,48.426518
   LCZ42_21206_Mumbai,72.560788,19.530949,73.162941,18.663594
   LCZ42_21523_Tehran,51.054822,35.867443,51.689530,35.483188
   LCZ42_21571_Milan,8.678807,45.845588,9.469482,45.375224
   LCZ42_21588_Rome,12.248669,42.133685,12.722877,41.728904
   LCZ42_21671_Tokyo,139.648113,35.768641,139.916600,35.547763
   LCZ42_21711_Nairobi,36.676004,-1.194833,36.988391,-1.437399
   LCZ42_21930_Amsterdam,3.949377,52.933880,5.424446,52.112622
   LCZ42_22042_Islamabad,72.551138,33.945460,73.420891,33.420416
   LCZ42_22167_Lisbon,-9.638041,38.967538,-8.713186,38.454358
   LCZ42_22481_Capetown,18.068579,-33.638258,18.982263,-34.386916
   LCZ42_22549_Madrid,-4.405077,41.187813,-2.863638,39.849460
   LCZ42_22606_Zurich,8.231088,47.540191,8.842113,47.171035
   LCZ42_22691_Istanbul,27.809808,41.796044,30.039563,40.654508
   LCZ42_22812_Cairo,31.019802,30.416066,31.544441,29.636155
   LCZ42_23052_losangeles,-118.693810,34.959400,-117.651311,33.715936
   LCZ42_23083_newyork,-74.603266,41.135263,-73.474235,40.337624
   LCZ42_23130_sanfrancisco,-122.715466,37.956750,-122.094341,37.552527
   LCZ42_23174_washingtondc,-77.368632,39.102813,-76.690746,38.605513
   LCZ42_23610_Dongying,118.428977,37.845294,119.330668,37.316333
   LCZ42addon_20058_buenosaires,-58.395180,-34.572510,-58.365044,-34.596296
   LCZ42addon_20119_Dhaka,90.366658,23.838644,90.447933,23.747041
   LCZ42addon_20275_Salvador,-38.503302,-12.918374,-38.482057,-12.939130
   LCZ42addon_22044_Orangitown,66.963322,24.991502,67.025027,24.911086
   LCZ42addon_22078_Lima,-77.034752,-11.950400,-76.939538,-12.240308
   LCZ42addon_22109_Quezon,121.040535,14.715325,121.123104,14.504536
   LCZ42addon_22956_Chicago,-87.650058,41.897046,-87.607611,41.870257
   LCZ42addon_23098_Philadelphia,-75.183880,39.964269,-75.156902,39.943585
   LCZ42addon_23217_Caracas,-66.927463,10.498394,-66.780774,10.449502
```

## Downloading Sentinel-2 data
This procedure has been developed to download the "best" complete set of tiles (a single tile product per tile ID) covering all of the ROI with products as cloud-free as available while being acquired at most similar dates/times.

1. **For each ROI, identify all candidate products (tiles)** \
Candidate tiles are those ones intersecting with the ROI.
This is realized by running a dryrun query without contraints on the cloud coverage. 
2. **Identify all unique tile IDs** \
Simple scan of all (.SAFE) file names returned from the query (see previous step) with subsequent identification of the set of *unique* tile IDs intersecting with the ROI. A tile ID is a string following the naming convention "Txxxxx" like, e.g., "T23KKQ".
3. **Find least cloudy product(s) for each previously identified tile ID** \
For each unique tile ID, starting from ```cloudCover=[cloudCoverMin,cloudCoverMax]=[0,0]``` (ideal case), find the lowest parameter value for ```cloudCoverMax```, for which the query finds a non-empty set of products. In this simple implementation, ```cloudCoverMax``` is gradually incremeted one percentage at a time. Note that binary search would be asymptotically more efficient but an over-kill here since, in the vast majority of cases, minimum values for ```cloudCoverMax``` are expected to be found near 0.
4. **Find best set of unique tiles (optionally: constrain to daylight observation)** \
If the query finds multiple tiles corresponding to the same tile ID, find the set of tiles (each of which corresponding to a different tile ID) whose elements were acquired at dates/times as similar to each other as possible. This is realized by formulating and solving a shortest path problem using an undirected graph with adjecency lists, where verteces corresond to acquisition dates/times and edges correspond to absolute time differences.
5. **Download tiles**\
Self-explaining.
6. **Double-check that there are no multiple products corresponding to the same tile ID left**\
Self-explaining.

## Atmospheric Correction (L1C -> L2A)
- extract zipped ```.SAFE``` folders from ```*.SAFE.zip``` to ```*.SAFE``` using, e.g., ```unzip```: \
``` unzip S2*_MSIL1C_201*_N*_R*_T*_*.SAFE.zip```
- 

~/Downloads/Sen2Cor-02.05.05-Linux64/bin/L2A_Process S2B_MSIL1C_20171215T101419_N0206_R022_T32UPU_20171215T121420.SAFE



## Building a mosaic for each ROI


Follow the instructions in [Samual Brower's documentation of sen2mosaic](https://sen2mosaic.readthedocs.io/en/latest/setup.html). The essential steps, without description, are as follows:

1) Setup Instructions  
    1) Requirements  
    - 8 GB of RAM to run sen2cor  
    2) Install anaconda python, gdal and opencv (replace ```2-5.1.0``` by numbers of latest version):  
    - ```wget https://repo.anaconda.com/archive/Anaconda2-5.1.0-Linux-x86_64.sh```  
    - ```chmod +x Anaconda2-5.1.0-Linux-x86_64.sh```  
    - ```./Anaconda2-5.1.0-Linux-x86_64.sh```  
    - ```conda install -c anaconda gdal```  
    - ```conda install -c conda-forge opencv```  
    3) Installing sen2cor (replace ```02.05.05``` and ```2.5.5``` by numbers of latest version)
    - ```wget http://step.esa.int/thirdparties/sen2cor/2.5.5/Sen2Cor-02.05.05-Linux64.run chmod +x Sen2Cor-02.05.05-Linux64.run ./Sen2Cor-02.05.05-Linux64.run```
    - ```echo "source ~/Sen2Cor-02.05.05-Linux64/L2A_Bashrc" >> ~/.bashrc```  
    - ```exec -l $SHELL```  
    4) Installing sentinelsat (should be redundant considering that other Sentinel-2 download interfaces are used here)
    - ```pip install sentinelsat``` 
    5) Installing sen2mosaic  
    - ```git clone https://sambowers@bitbucket.org/sambowers/sen2mosaic.git```
    - ```echo "alias s2m='_s2m() { python ~/sen2mosaic/sen2mosaic/\"\$1\".py \$(shift; echo \"\$@\") ;}; _s2m'" >> ~/.bashr```

2) Command line tools
    1) Getting L1C data (example)
    - ```s2m download -u user.name -p supersecret -t 36KWA -s 20170501 -e 20170630 -c 30 -r -o ~/path/to/36KWA_data/```
    2) Processing to L2A
    - ```s2m preprocess -res 20 -n 3 /path/to/36KWA_data```
    3) Processing to a mosaic (example)
    - ```s2m mosaic -te 700000 7900000 900000 8100000 -e 32736 -res 20 -o /path/to/output/ -n my_output -b AGGRESSIVE -c /path/to/36KWA_data```

3) Worked example on the command line
    1) Preparation
    - ```cd /home/user/DATA```
    - ```mkdir worked_example```
    - ```cd worked_example```
    - ```mkdir 36KWA```
    - ```mkdir 36KWB```
    - ```cd 36KWA```
    2) Downloading data
    - ```s2m download -u user.name -p supersecret -t 36KWA -s 20170501 -e 20170630 -c 30```
    3) Atmopsheric correction and cloud masking
    - ```s2m preprocess -res 20 -t 36KWA -v```
    4) Repeat downloading and atmospheric correction steps for other tiles ...
    5) Generating a cloud-free mosaic image
    - ```cd /home/user/DATA/worked_example/```
    - ```s2m mosaic -te 500000 7500000 600000 7700000 -e 32736 -res 20 -n worked_example -b AGGRESSIVE -c -v ./36KW*```
    6)  Viewing data ..

