#!/usr/bin/env python3
# coding: utf8

import argparse
import numpy as np
import imageio
import re
import sys
# import math
from osgeo import gdal, osr
# import sres
from collections import defaultdict
import os

# from skimage import io, img_as_uint

parser = argparse.ArgumentParser(
    description=
    "Crop Sentinel-2 (and possibly other) data based on eihter (absolut lon/lat) or (relative x/y) coordiinates.",
    formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument(
    "data_file",
    help=
    "An input sentinel-2 data file. This can be either the original ZIP file, or the S2A[...].xml file in a SAFE directory extracted from that ZIP."
)

parser.add_argument(
    "output_file",
    nargs="?",
    help=
    "A target data file. See also the --save_prefix option, and the --output_file_format option (default is ENVI)."
)

parser.add_argument(
    "--write_cropped_input_data",
    action="store_true",
    help=
    "Specify whether or not the input data cropped by the ROI (lon/lat) should be saved. (default is True)"
)

parser.add_argument(
    "--roi_lon_lat",
    default="",
    help=
    "Sets the region of interest to extract, WGS84, decimal notation. Use this syntax: lon_1,lat_1,lon_2,lat_2. The order of points 1 and 2 does not matter: the region of interest extends to the min/max in each direction. Example: --roi_lon_lat=-1.12132,44.72408,-0.90350,44.58646"
)

parser.add_argument(
    "--roi_x_y",
    default="",
    help=
    "Sets the region of interest to extract as pixels locations on the 10m bands. Use this syntax: x_1,y_1,x_2,y_2. The order of points 1 and 2 does not matter: the region of interest extends to the min/max in each direction and to nearby 60m pixel boundaries."
)

parser.add_argument(
    "--list_bands",
    action="store_true",
    help=
    "List bands in the input file subdata set matching the selected UTM zone, and exit."
)

parser.add_argument(
    "--select_bands",
    default="B1,B2,B3,B4,B5,B6,B7,B8,B8A,B9,B10,B11,B12",
    help=
    "Select which bands to process and include in the output file (default=all). Using comma-separated band names. Excluding bands is tempting to accelerate computations."
)

parser.add_argument(
    "--list_UTM",
    action="store_true",
    help=
    "List all UTM zones present in the input file, together with their coverage of the ROI in 10m x 10m pixels."
)

parser.add_argument(
    "--select_UTM",
    default="",
    help=
    "Select a UTM zone. The default is to select the zone with the largest coverage of the ROI."
)

parser.add_argument(
    "--list_output_file_formats",
    action="store_true",
    help=
    "If specified, list all supported raster output file formats declared by GDAL and exit. Some of these formats may be inappropriate for storing Sentinel-2 multispectral data."
)

parser.add_argument(
    "--output_file_format",
    default="ENVI",
    help=
    "Specifies the name of a GDAL driver that supports file creation, like ENVI or GTiff. If no such driver exists, or if the format is \"npz\", then save all bands instead as a compressed python/numpy file"
)

# parser.add_argument(
#     "--do_not_copy_original_bands",
#     action="store_true",
#     help=
#     "The default is to copy the original selected 10m bands into the output file in addition to the super-resolved bands. This way, the output file may be used as a 10m version of the original Sentinel-2 file. This option cancels that behavior and only outputs the super-resolved data."
# )

parser.add_argument(
    "--save_prefix",
    default="",
    help=
    "If set, speficies the name of a prefix for all output files. Use a trailing / to save into a directory. The default of no prefix will save into the current directory. Example: --save_prefix result/"
)

parser.add_argument(
    "--write_images",
    action="store_true",
    help=
    "If set, write PNG images for the original and the superresolved bands, together with a composite rgb image (first three 10m bands), all with a quick and dirty clipping to 99%% of the original bands dynamic range and a quantization of the values to 256 levels. These images are convenient to visually compare the original and super-resolved bands, but you should probably use the full output file for accuracy."
)

# parser.add_argument(
#     "--num_threads",
#     default=-1,
#     type=int,
#     help=
#     "If >0, speficies the number of threads to use. The default -1 means the maximum number of threads."
# )

# parser.add_argument(
#     "--block_size_hint",
#     default=30,
#     type=int,
#     help=
#     "If set, specifies the approximate size of sub-image blocks that will be used in a multithreaded scenario. Each thread takes one image block, with an overlapping pixel between blocks. Setting this value too low only increases overhead, but setting it too high may decrease parallelism. The ideal number of blocks is a multiple of the number of threads, so the block size hint is adjusted to best respect this constraint."
# )

# parser.add_argument(
#     "--num_blocks",
#     default="",
#     help=
#     "If set, forces the use of these number of image blocks in each dimension. Only useful in a multithreaded context. Syntax is --num_blocks nbx,nby where nbx is the number of blocks to divide the image into along the X dimension, and similarly for nby for Y."
# )
#
# parser.add_argument(
#     "--max_iterations",
#     default=30,
#     type=int,
#     help=
#     "Specifies the maximum number of iterations for the internal iterative solver. Scales roughly linearly with the computation time, but reducing this too much will decrease the result quality."
# )
#
# parser.add_argument(
#     "--tolerance",
#     default=1e-4,
#     type=float,
#     help=
#     "Specifies the tolerance for the convergence of the internal iterative solver. Decreasing this parameter may marginally improve some fine-structure details, but may drastically increase the computation time."
# )
#
# parser.add_argument(
#     "--use_inner_iterations",
#     action="store_true",
#     default=False,
#     help=
#     "Using inner iterations and lesser max_iterations may sometimes be faster."
# )
#
# parser.add_argument(
#     "--debug_progress",
#     action="store_true",
#     default=False,
#     help=
#     "If specified, the internal solver iterations and result are displayed. Best used with a single thread."
# )
#
# parser.add_argument(
#     "--internal_test", default=0, type=int, help=argparse.SUPPRESS)
#
# parser.add_argument(
#     "--quality_assessment_mode",
#     action="store_true",
#     default=False,
#     help=
#     "If specified, quality assessment measures are computed. In this mode, the original data is not super-resolved to 10m resolution. Instead, the 10m and 20m bands are downsampled into 20m and 40m bands (and written images are these downsampled versions). The 40m bands are super-resolved and then compared against the original 20m bands. Quality measurements are averaged over all bands. do_not_copy_original_bands"
# )

args = parser.parse_args()
# globals().update(args.__dict__)

if args.list_output_file_formats:
    dcount = gdal.GetDriverCount()
    for didx in range(dcount):
        driver = gdal.GetDriver(didx)
        if driver:
            metadata = driver.GetMetadata()
        # if driver and metadata.has_key(gdal.DCAP_CREATE) and metadata[gdal.DCAP_CREATE] == 'YES' and metadata.has_key(gdal.DCAP_RASTER) and metadata[gdal.DCAP_RASTER] == 'YES':
        if (driver and gdal.DCAP_CREATE in metadata
                and metadata[gdal.DCAP_CREATE] == 'YES'
                and gdal.DCAP_RASTER in metadata
                and metadata[gdal.DCAP_RASTER] == 'YES'):
            name = driver.GetDescription()
            # if metadata.has_key("DMD_LONGNAME"):
            if ("DMD_LONGNAME" in metadata):
                name += ": " + metadata["DMD_LONGNAME"]
            else:
                name = driver.GetDescription()
            # if metadata.has_key("DMD_EXTENSIONS"):
            if ("DMD_EXTENSIONS" in metadata):
                name += " (" + metadata["DMD_EXTENSIONS"] + ")"
            print(name)
    sys.exit(0)

# convert comma separated band list into a list
select_bands = [x for x in re.split(',', args.select_bands)]

if args.roi_lon_lat:
    roi_lon1, roi_lat1, roi_lon2, roi_lat2 = [
        float(x) for x in re.split(',', args.roi_lon_lat)
    ]
else:
    roi_lon1, roi_lat1, roi_lon2, roi_lat2 = -180, -90, 180, 90

if args.roi_x_y:
    roi_x1, roi_y1, roi_x2, roi_y2 = [
        float(x) for x in re.split(',', args.roi_x_y)
    ]

raster = gdal.Open(args.data_file)

# if args.num_blocks:
#     nbx, nby = [int(n) for n in re.split(',', args.num_blocks)]
# else:
nbx, nby = 0, 0

datasets = raster.GetSubDatasets()
tenMsets = []
twentyMsets = []
sixtyMsets = []
unknownMsets = []
for (dsname, dsdesc) in datasets:
    if '10m resolution' in dsdesc:
        tenMsets += [(dsname, dsdesc)]
    elif '20m resolution' in dsdesc:
        twentyMsets += [(dsname, dsdesc)]
    elif '60m resolution' in dsdesc:
        sixtyMsets += [(dsname, dsdesc)]
    else:
        unknownMsets += [(dsname, dsdesc)]

# case where we have several UTM in the data set
# => select the one with maximal coverage of the study zone
utm_idx = 0
utm = args.select_UTM
all_utms = defaultdict(int)
xmin, ymin, xmax, ymax = 0, 0, 0, 0
largest_area = -1
# process even if there is only one 10m set, in order to get roi -> pixels
for (tmidx, (dsname, dsdesc)) in enumerate(tenMsets + unknownMsets):
    ds = gdal.Open(dsname)
    if args.roi_x_y:
        tmxmin = max(min(roi_x1, roi_x2, ds.RasterXSize - 1), 0)
        tmxmax = min(max(roi_x1, roi_x2, 0), ds.RasterXSize - 1)
        tmymin = max(min(roi_y1, roi_y2, ds.RasterYSize - 1), 0)
        tmymax = min(max(roi_y1, roi_y2, 0), ds.RasterYSize - 1)
        # enlarge to the nearest 60 pixel boundary for the super-resolution
        tmxmin = int(tmxmin / 6) * 6
        tmxmax = int((tmxmax + 1) / 6) * 6 - 1
        tmymin = int(tmymin / 6) * 6
        tmymax = int((tmymax + 1) / 6) * 6 - 1
        # quality assessment downsamples 20m -> 40m then superresolves back
        # => multiple of 4
        # make it so we can reuse the same region for the full image without
        # qam => multiple of 4 and 6 = multiple of 12
        # if args.quality_assessment_mode:
        #     tmxmin = int(tmxmin / 12) * 12
        #     tmxmax = int((tmxmax + 1) / 12) * 12 - 1
        #     tmymin = int(tmymin / 12) * 12
        #     tmymax = int((tmymax + 1) / 12) * 12 - 1
    elif not args.roi_lon_lat:
        tmxmin = 0
        tmxmax = ds.RasterXSize - 1
        tmymin = 0
        tmymax = ds.RasterYSize - 1
    else:
        xoff, a, b, yoff, d, e = ds.GetGeoTransform()
        srs = osr.SpatialReference()
        srs.ImportFromWkt(ds.GetProjection())
        srsLatLon = osr.SpatialReference()
        srsLatLon.SetWellKnownGeogCS("WGS84")
        ct = osr.CoordinateTransformation(srsLatLon, srs)

        def to_xy(lon, lat):
            (xp, yp, h) = ct.TransformPoint(lon, lat, 0.)
            xp -= xoff
            yp -= yoff
            # matrix inversion
            det_inv = 1. / (a * e - d * b)
            x = (e * xp - b * yp) * det_inv
            y = (-d * xp + a * yp) * det_inv
            return (int(x), int(y))

        # CG added --->
        # (xoff_ROI_orig, yoff_ROI_orig, h) = ct.TransformPoint(min(roi_lon1, roi_lon2), max(roi_lat1, roi_lat2), 0.)
        # xoff_ROI = max(xoff_ROI_orig, xoff)
        # yoff_ROI = min(yoff_ROI_orig, yoff)
        # (upper_left_x_UTM, x_size, x_rotation, upper_left_y_UTM, y_rotation, y_size) = ds10.GetGeoTransform()
        # print('xoff_ROI_orig = ', xoff_ROI_orig)
        # print('yoff_ROI_orig = ', yoff_ROI_orig)
        # print('xoff = ', xoff)
        # print('yoff = ', yoff)
        # print('xoff_ROI = ', xoff_ROI)
        # print('yoff_ROI = ', yoff_ROI)
        # <---
        x1, y1 = to_xy(roi_lon1, roi_lat1)
        x2, y2 = to_xy(roi_lon2, roi_lat2)
        tmxmin = max(min(x1, x2, ds.RasterXSize - 1), 0)
        tmxmax = min(max(x1, x2, 0), ds.RasterXSize - 1)
        tmymin = max(min(y1, y2, ds.RasterYSize - 1), 0)
        tmymax = min(max(y1, y2, 0), ds.RasterYSize - 1)
        # enlarge to the nearest 60 pixel boundary for the super-resolution
        tmxmin = int(tmxmin / 6) * 6
        tmxmax = int((tmxmax + 1) / 6) * 6 - 1
        tmymin = int(tmymin / 6) * 6
        tmymax = int((tmymax + 1) / 6) * 6 - 1
        xoff_ROI = xoff + tmxmin * a
        yoff_ROI = yoff - tmymin * (-e)
        # quality assessment downsamples 20m -> 40m then superresolves back
        # if args.quality_assessment_mode:
        #     tmxmin = int(tmxmin / 4) * 4
        #     tmxmax = int((tmxmax + 1) / 4) * 4 - 1
        #     tmymin = int(tmymin / 4) * 4
        #     tmymax = int((tmymax + 1) / 4) * 4 - 1
    area = (tmxmax - tmxmin + 1) * (tmymax - tmymin + 1)
    current_utm = dsdesc[dsdesc.find("UTM"):]
    if area > all_utms[current_utm]:
        all_utms[current_utm] = area
    if current_utm == args.select_UTM:
        xmin, ymin, xmax, ymax = tmxmin, tmymin, tmxmax, tmymax
        utm_idx = tmidx
        utm = current_utm
        break
    if area > largest_area:
        xmin, ymin, xmax, ymax = tmxmin, tmymin, tmxmax, tmymax
        largest_area = area
        utm_idx = tmidx
        utm = dsdesc[dsdesc.find("UTM"):]

if args.list_UTM:
    print("List of UTM zones (with ROI coverage in pixels):")
    for u in all_utms:
        print("%s (%d)" % (u, all_utms[u]))
    sys.exit(0)

print("Selected UTM Zone:", utm)
print(
    "Selected pixel region: --roi_x_y=%d,%d,%d,%d" % (xmin, ymin, xmax, ymax))
print("Image size: width=%d x height=%d" % (xmax - xmin + 1, ymax - ymin + 1))

if xmax < xmin or ymax < ymin:
    print("Invalid region of interest / UTM Zone combination")
    sys.exit(0)

selected_10m_data_set = None
if not tenMsets:
    selected_10m_data_set = unknownMsets[0]
else:
    selected_10m_data_set = tenMsets[utm_idx]
selected_20m_data_set = None
for (dsname, dsdesc) in enumerate(twentyMsets):
    if utm in dsdesc:
        selected_20m_data_set = (dsname, dsdesc)
# if not found, assume the listing is in the same order
# => OK if only one set
if not selected_20m_data_set:
    selected_20m_data_set = twentyMsets[utm_idx]
selected_60m_data_set = None
for (dsname, dsdesc) in enumerate(sixtyMsets):
    if utm in dsdesc:
        selected_60m_data_set = (dsname, dsdesc)
if not selected_60m_data_set:
    selected_60m_data_set = sixtyMsets[utm_idx]

ds10 = gdal.Open(selected_10m_data_set[0])
ds20 = gdal.Open(selected_20m_data_set[0])
ds60 = gdal.Open(selected_60m_data_set[0])

xoff, a, b, yoff, d, e = ds10.GetGeoTransform()
srs = osr.SpatialReference()
srs.ImportFromWkt(ds.GetProjection())
srsLatLon = osr.SpatialReference()
srsLatLon.SetWellKnownGeogCS("WGS84")
ct = osr.CoordinateTransformation(srs, srsLatLon)


def to_lonlat(x, y):
    (lon, lat, h) = ct.TransformPoint(xoff + x * a + y * b,
                                      yoff + x * d + y * e, 0.)
    return (lon, lat)


(lon1, lat1) = to_lonlat(xmin, ymin)
(lon2, lat2) = to_lonlat(xmax, ymax)
print("Selected lon/lat region: --roi_lon_lat=%.20f,%.20f,%.20f,%.20f" %
      (lon1, lat1, lon2, lat2))


def validate_description(description):
    m = re.match("(.*?), central wavelength (\d+) nm", description)
    if m:
        return m.group(1) + " (" + m.group(2) + " nm)"
    # Some HDR restrictions... ENVI band names should not include commas
    if output_file_format == 'ENVI' and ',' in description:
        pos = description.find(',')
        return description[:pos] + description[(pos + 1):]
    return description


if args.list_bands:
    print("\n10m bands:")
    for b in range(0, ds10.RasterCount):
        print("- " +
              validate_description(ds10.GetRasterBand(b + 1).GetDescription()))
    print("\n20m bands:")
    for b in range(0, ds20.RasterCount):
        print("- " +
              validate_description(ds20.GetRasterBand(b + 1).GetDescription()))
    print("\n60m bands:")
    for b in range(0, ds60.RasterCount):
        print("- " +
              validate_description(ds60.GetRasterBand(b + 1).GetDescription()))
    print("")


def get_band_short_name(description):
    if ',' in description:
        return description[:description.find(',')]
    if ' ' in description:
        return description[:description.find(' ')]
    return description[:3]


validated_10m_bands = []
validated_10m_indices = []
validated_20m_bands = []
validated_20m_indices = []
validated_60m_bands = []
validated_60m_indices = []
validated_descriptions = defaultdict(str)

sys.stdout.write("Selected 10m bands:")
for b in range(0, ds10.RasterCount):
    desc = validate_description(ds10.GetRasterBand(b + 1).GetDescription())
    shortname = get_band_short_name(desc)
    if shortname in select_bands:
        sys.stdout.write(" " + shortname)
        select_bands.remove(shortname)
        validated_10m_bands += [shortname]
        validated_10m_indices += [b]
        validated_descriptions[shortname] = desc
sys.stdout.write("\nSelected 20m bands:")
for b in range(0, ds20.RasterCount):
    desc = validate_description(ds20.GetRasterBand(b + 1).GetDescription())
    shortname = get_band_short_name(desc)
    if shortname in select_bands:
        sys.stdout.write(" " + shortname)
        select_bands.remove(shortname)
        validated_20m_bands += [shortname]
        validated_20m_indices += [b]
        validated_descriptions[shortname] = desc
sys.stdout.write("\nSelected 60m bands:")
for b in range(0, ds60.RasterCount):
    desc = validate_description(ds60.GetRasterBand(b + 1).GetDescription())
    shortname = get_band_short_name(desc)
    if shortname in select_bands:
        sys.stdout.write(" " + shortname)
        select_bands.remove(shortname)
        validated_60m_bands += [shortname]
        validated_60m_indices += [b]
        validated_descriptions[shortname] = desc
sys.stdout.write("\n")

if args.list_bands:
    sys.exit(0)

# if args.quality_assessment_mode:
#     if not validated_10m_indices or not validated_20m_indices:
#         print("Error: quality assessment requires both 10m and 20m bands")
#         sys.exit(1)
#     if validated_60m_indices:
#         print("Warning: Ignoring 60m bands in quality assessment mode")
#         validated_60m_bands = []
#         validated_60m_indices = []

if args.output_file:
    if not os.path.exists(args.save_prefix):
        os.makedirs(args.save_prefix)
    # output_file = args.save_prefix + '/' + args.output_file
    # CG added --->
    output_file_croppedInput = dict()
    output_file_croppedInput[
        '10m'] = args.save_prefix + '/' + args.output_file + '_10m'
    output_file_croppedInput[
        '20m'] = args.save_prefix + '/' + args.output_file + '_20m'
    output_file_croppedInput[
        '60m'] = args.save_prefix + '/' + args.output_file + '_60m'
    # <---
    # Some HDR restrictions... ENVI file name should be the .bin, not the .hdr
    if args.output_file_format == 'ENVI' and (args.output_file[-4:] == '.hdr'
                                              or args.output_file[-4:] == '.HDR'):
        # output_file = output_file[:-4] + '.bin'
        output_file_croppedInput['10m'] = output_file_croppedInput['10m'][:-4] + '.bin'
        output_file_croppedInput['20m'] = output_file_croppedInput['20m'][:-4] + '.bin'
        output_file_croppedInput['60m'] = output_file_croppedInput['60m'][:-4] + '.bin'

if validated_10m_indices:
    print("Loading selected data from: %s" % selected_10m_data_set[1])
    data10 = np.empty(
        [ymax - ymin + 1, xmax - xmin + 1,
         len(validated_10m_indices)])
    for i, b in enumerate(validated_10m_indices):
        data10[:, :, i] = ds10.GetRasterBand(b + 1).ReadAsArray(
            xoff=xmin,
            yoff=ymin,
            win_xsize=xmax - xmin + 1,
            win_ysize=ymax - ymin + 1,
            buf_xsize=xmax - xmin + 1,
            buf_ysize=ymax - ymin + 1)

if validated_20m_indices:
    print("Loading selected data from: %s" % selected_20m_data_set[1])
    data20 = np.empty([(ymax - ymin + 1) // 2, (xmax - xmin + 1) // 2,
                       len(validated_20m_indices)])
    for i, b in enumerate(validated_20m_indices):
        data20[:, :, i] = ds20.GetRasterBand(b + 1).ReadAsArray(
            xoff=xmin // 2,
            yoff=ymin // 2,
            win_xsize=(xmax - xmin + 1) // 2,
            win_ysize=(ymax - ymin + 1) // 2,
            buf_xsize=(xmax - xmin + 1) // 2,
            buf_ysize=(ymax - ymin + 1) // 2)

if validated_60m_indices:
    print("Loading selected data from: %s" % selected_60m_data_set[1])
    data60 = np.empty([(ymax - ymin + 1) // 6, (xmax - xmin + 1) // 6,
                       len(validated_60m_indices)])
    for i, b in enumerate(validated_60m_indices):
        data60[:, :, i] = ds60.GetRasterBand(b + 1).ReadAsArray(
            xoff=xmin // 6,
            yoff=ymin // 6,
            win_xsize=(xmax - xmin + 1) // 6,
            win_ysize=(ymax - ymin + 1) // 6,
            buf_xsize=(xmax - xmin + 1) // 6,
            buf_ysize=(ymax - ymin + 1) // 6)

# if args.quality_assessment_mode:
#     print("Downsampling the 10m and 20m data into 20m and 40m bands")
#     data10 = sres.decrease_resolution_by_two(data10)
#     qam_ori20 = data20
#     data20 = sres.decrease_resolution_by_two(data20)


# The percentile_data argument is used to plot superresolved and original data
# with a comparable black/white scale
def save_band(data, name, percentile_data=None):
    if percentile_data is None:
        percentile_data = data
    mi, ma = np.percentile(percentile_data, (1, 99))
    band_data = np.clip(data, mi, ma)
    band_data = (band_data - mi) / (ma - mi)
    imageio.imsave(args.save_prefix + name + ".png",
                   band_data)  # img_as_uint(band_data))


# if(args.write_cropped_input_data):
#     # data10 data20 data60
#     print("here we are")

if args.write_images:
    for b, bname in enumerate(validated_10m_bands):
        save_band(data10[:, :, b], bname)
    for b, bname in enumerate(validated_60m_bands):
        save_band(data60[:, :, b], bname)
    save_band(data10[:, :, 0:3], "RGB")
    # if args.quality_assessment_mode:
    #     for b, bname in enumerate(validated_20m_bands):
    #         save_band(qam_ori20[:, :, b], bname)
    #     for b, bname in enumerate(validated_20m_bands):
    #         save_band(data20[:, :, b], "DS" + bname, qam_ori20[:, :, b])
    # else:
    for b, bname in enumerate(validated_20m_bands):
        save_band(data20[:, :, b], bname)

# def monitor(percent_completed, time_spent):
#     if percent_completed % 10 == 0:
#         sys.stdout.write("%d" % percent_completed)
#         sys.stdout.flush()
#     elif percent_completed % 5 == 0:
#         sys.stdout.write(".")
#         sys.stdout.flush()
#     if percent_completed == 100:
#         print(" (%.3fs)" % time_spent)
#     return True

# Selective processing of 60m->20m and/or 20m->10m depending on band selection

# named_args = {
#     'progress_monitor': monitor,
#     'num_threads': args.num_threads,
#     'max_iterations': args.max_iterations,
#     'use_inner_iterations': args.use_inner_iterations,
#     'tolerance': args.tolerance,
#     'block_size_hint': args.block_size_hint,
#     'debug_progress': args.debug_progress,
#     'nbx': nbx,
#     'nby': nby,
#     'internal_test': args.internal_test
# }

# if validated_60m_bands and (validated_20m_bands or validated_10m_bands):
#     print("Super-resolving the 60m data into 20m bands")
#     if validated_10m_bands:
#         # print "Averaging the 10m bands into virtual 20m bands"
#         avg10 = sres.decrease_resolution_by_two(data10)
#         source_20_for_sr_at_60 = np.concatenate((data20, avg10), axis=2)
#     else:
#         source_20_for_sr_at_60 = data20
#         avg10 = None
#     # sr20 = sres.super_resolve(data60, source_20_for_sr_at_60, **named_args)
# else:
#     sr20 = None
#     avg10 = None

# sr_band_names = []
# if validated_10m_bands and (validated_20m_bands or sr20):
# if validated_20m_bands and sr20 is not None:
#     # print("Super-resolving the 20m and the 60m data into 10m bands")
#     # extended_20 = np.concatenate((data20, sr20), axis=2)
#     # sr_band_names = validated_20m_bands + validated_60m_bands
# elif sr20:
#     print("Super-resolving the 60m data into 10m bands")
#     extended_20 = sr20
#     sr_band_names = validated_60m_bands
# else:
#     # if args.quality_assessment_mode:
#     #     print("Super-resolving the 40m data into 20m bands")
#     # else:
#     print("Super-resolving the 20m data into 10m bands")
#     extended_20 = data20
#     sr_band_names = validated_20m_bands
# sr10 = sres.super_resolve(extended_20, data10, **named_args)
# else:
#     sr10 = None

# if sr10 is None and sr20 is None:
#     print("No super-resolution performed, exiting")
#     sys.exit(0)

if args.output_file_format != "npz":
    revert_to_npz = True
    driver = gdal.GetDriverByName(args.output_file_format)
    if driver:
        metadata = driver.GetMetadata()
        # if metadata.has_key(
        #         gdal.DCAP_CREATE) and metadata[gdal.DCAP_CREATE] == 'YES':
        if (gdal.DCAP_CREATE in metadata
                and metadata[gdal.DCAP_CREATE] == 'YES'):
            revert_to_npz = False
    if revert_to_npz:
        print(
            "Gdal doesn't support creating %s files" % args.output_file_format)
        print("Writing to npz as a fallback")
        output_file_format = "npz"
    # bands = None
    # CG added --->
    bands_croppedInput = {'10m': None, '20m': None, '60m': None}
    # <---
else:
    # bands = dict()
    # result_dataset = None
    # CG added --->
    bands_croppedInput = {'10m': dict(), '20m': dict(), '60m': dict()}
    result_dataset_croppedInput = {'10m': None, '20m': None, '60m': None}
    # <---

# bidx = 0
# all_descriptions = []
# source_band = dict()

# CG: added --->
# resID = '10m' or '20m' or '60m'
source_band = dict()
bidx_croppedInput = {'10m': 0, '20m': 0, '60m': 0}
all_descriptions_croppedInput = {'10m': [], '20m': [], '60m': []}
# source_band_croppedInput = {'10m': dict(), '20m': dict(), '60m': dict()}
# <---

if args.write_images:
    # if args.quality_assessment_mode:
    #     for bi, bn in enumerate(validated_20m_bands):
    #         source_band["SR" + bn] = qam_ori20[:, :, bi]
    # else:
    # for bi, bn in enumerate(validated_10m_bands):
    #     # source_band["SR" + bn] = data20[:, :, bi]
    #     source_band[bn] = data10[:, :, bi]
    for bi, bn in enumerate(validated_20m_bands):
        # source_band["SR" + bn] = data20[:, :, bi]
        source_band[bn] = data20[:, :, bi]
    for bi, bn in enumerate(validated_60m_bands):
        # source_band["SR" + bn] = data60[:, :, bi]
        source_band[bn] = data60[:, :, bi]

# def write_band_data(data, description, shortname=None):
#     global all_descriptions
#     global bidx
#     all_descriptions += [description]
#     if output_file:
#         if output_file_format == "npz":
#             bands[description] = data
#         else:
#             bidx += 1
#             result_dataset.GetRasterBand(bidx).SetDescription(description)
#             result_dataset.GetRasterBand(bidx).WriteArray(data)
#     if args.write_images and shortname:
#         save_band(data, shortname, source_band[shortname])


def write_band_data_croppedInput(data, description, resID, shortname=None):
    global all_descriptions_croppedInput
    global bidx_croppedInput
    all_descriptions_croppedInput[resID] += [description]
    if output_file_croppedInput[resID]:
        if args.output_file_format == "npz":
            bands_croppedInput[resID][description] = data
        else:
            bidx_croppedInput[resID] += 1
            result_dataset_croppedInput[resID].GetRasterBand(
                bidx_croppedInput[resID]).SetDescription(description)
            result_dataset_croppedInput[resID].GetRasterBand(
                bidx_croppedInput[resID]).WriteArray(data)
    if args.write_images and shortname:
        save_band(data, shortname, source_band[shortname])


result_dataset_croppedInput = dict()

# if sr10 is not None:
sys.stdout.write("Writing")
# if not args.do_not_copy_original_bands:
# if args.quality_assessment_mode:
#     sys.stdout.write(" the 10m bands downsampled to 20m and")
# else:
sys.stdout.write(" the 10m bands")
# if output_file:
# print('data10.shape = ', data10.shape)
# print('sr10.shape = ', sr10.shape)
# print('data20.shape = ', data20.shape)
# print('sr20.shape = ', sr20.shape)
# print('data60.shape = ', data60.shape)
# result_dataset = driver.Create(
#     output_file, data10.shape[1], data10.shape[0],
#     data10.shape[2] + sr10.shape[2], gdal.GDT_Float64)
# result_dataset.SetGeoTransform(ds10.GetGeoTransform())
# result_dataset.SetProjection(ds10.GetProjection())

# CG: added --->
print("##############################")
print(data10.shape[1])
print(data10.shape[0])
print(data10.shape[2])
#output_file_croppedInput['10m'].
#print(gdal.GDT_Float64)
print("##############################")
result_dataset_croppedInput['10m'] = driver.Create(
    output_file_croppedInput['10m'], data10.shape[1], data10.shape[0],
    data10.shape[2], gdal.GDT_Float64)
# result_dataset_croppedInput['10m'].SetGeoTransform(ds10.GetGeoTransform())
# # (upper_left_x, x_size, x_rotation, upper_left_y, y_rotation, y_size) = ds10.GetGeoTransform()
# # result_dataset_croppedInput['10m'].SetGeoTransform(upper_left_x, x_size, x_rotation, upper_left_y, y_rotation, y_size)
geoTransf10m = ds10.GetGeoTransform()
# (upper_left_x_UTM, x_size, x_rotation, upper_left_y_UTM, y_rotation, y_size) = ds10.GetGeoTransform()
#print('ds10.shape = ', ds10.shape[0], '\n')
print('data10.shape = ', data10.shape[0], '\n')
print("----------------\n geo transform 10m:")
print(geoTransf10m)
print("--------------------------")
# geoTransf10m[0] = xoff_ROI
# geoTransf10m[3] = yoff_ROI
geoTransf10m_new = (xoff_ROI, geoTransf10m[1], geoTransf10m[2], yoff_ROI,
                    geoTransf10m[4], geoTransf10m[5])
print(geoTransf10m_new)

result_dataset_croppedInput['10m'].SetGeoTransform(geoTransf10m_new)
result_dataset_croppedInput['10m'].SetProjection(ds10.GetProjection())
# ---
print("----------------\n geo transform 20m:")
geoTransf20m = ds20.GetGeoTransform()
print(geoTransf20m)
geoTransf20m_new = (xoff_ROI, geoTransf20m[1], geoTransf20m[2], yoff_ROI,
                    geoTransf20m[4], geoTransf20m[5])
print(geoTransf20m_new)
print("--------------------------")
result_dataset_croppedInput['20m'] = driver.Create(
    output_file_croppedInput['20m'], data20.shape[1], data20.shape[0],
    data20.shape[2], gdal.GDT_Float64)
#result_dataset_croppedInput['20m'].SetGeoTransform(ds20.GetGeoTransform())
result_dataset_croppedInput['20m'].SetGeoTransform(geoTransf20m_new)
result_dataset_croppedInput['20m'].SetProjection(ds20.GetProjection())
# ---
print("----------------\n geo transform 60m:")
geoTransf60m = ds60.GetGeoTransform()
print(geoTransf60m)
geoTransf60m_new = (xoff_ROI, geoTransf60m[1], geoTransf60m[2], yoff_ROI,
                    geoTransf60m[4], geoTransf60m[5])
print(geoTransf60m_new)
print("--------------------------")
result_dataset_croppedInput['60m'] = driver.Create(
    output_file_croppedInput['60m'], data60.shape[1], data60.shape[0],
    data60.shape[2], gdal.GDT_Float64)
#result_dataset_croppedInput['60m'].SetGeoTransform(ds60.GetGeoTransform())
result_dataset_croppedInput['60m'].SetGeoTransform(geoTransf60m_new)
result_dataset_croppedInput['60m'].SetProjection(ds60.GetProjection())
# <---

# # Write the original 10m bands
# for bi, bn in enumerate(validated_10m_bands):
#     write_band_data(data10[:, :, bi], validated_descriptions[bn])
# CG added --->
# Write the original 10m bands
# for bi, bn in enumerate(validated_10m_bands):
#     write_band_data_croppedInput(data10[:, :, bi], validated_descriptions[bn],
#                                  '10m', bn)
# for bi, bn in enumerate(validated_20m_bands):
#     write_band_data_croppedInput(data20[:, :, bi], validated_descriptions[bn],
#                                  '20m', bn)
# for bi, bn in enumerate(validated_60m_bands):
#     write_band_data_croppedInput(data60[:, :, bi], validated_descriptions[bn],
#                                  '60m', bn)
for bi, bn in enumerate(validated_10m_bands):
    write_band_data_croppedInput(data10[:, :, bi], validated_descriptions[bn],
                                 '10m')
for bi, bn in enumerate(validated_20m_bands):
    write_band_data_croppedInput(data20[:, :, bi], validated_descriptions[bn],
                                 '20m')
for bi, bn in enumerate(validated_60m_bands):
    write_band_data_croppedInput(data60[:, :, bi], validated_descriptions[bn],
                                 '60m')

# <---
# elif output_file:
#     result_dataset = driver.Create(output_file, data10.shape[1],
#                                    data10.shape[0], sr10.shape[2],
#                                    gdal.GDT_Float64)
#     result_dataset.SetGeoTransform(ds10.GetGeoTransform())
#     result_dataset.SetProjection(ds10.GetProjection())
# print(" the super-resolved bands in %s" % output_file)
# for bi, bn in enumerate(sr_band_names):
#     write_band_data(sr10[:, :, bi], "SR" + validated_descriptions[bn],
#                     "SR" + bn)
# else:
#     # 20m
#     sys.stdout.write("Writing")
#     if not args.do_not_copy_original_bands:
#         if output_file:
#             result_dataset = driver.Create(
#                 output_file, data20.shape[1], data20.shape[0],
#                 source_20_for_sr_at_60.shape[2] + sr20.shape[2],
#                 gdal.GDT_Float64)
#             result_dataset.SetGeoTransform(ds20.GetGeoTransform())
#             result_dataset.SetProjection(ds20.GetProjection())
#         if avg10:
#             # if args.quality_assessment_mode:
#             #     sys.stdout.write(
#             #         " the 10m bands downsampled then averaged to 40m and")
#             # else:
#             sys.stdout.write(" the averaged 10m bands and")
#             for bi, bn in enumerate(validated_10m_bands):
#                 write_band_data(avg10[:, :, bi],
#                                 "AVG" + validated_descriptions[bn])
#         if validated_20m_bands:
#             if args.quality_assessment_mode:
#                 sys.stdout.write(" the 20m bands downsampled to 40m and")
#             else:
#                 sys.stdout.write(" the original 20m bands and")
#             for bi, bn in enumerate(validated_20m_bands):
#                 write_band_data(data20[:, :, bi], validated_descriptions[bn])
#     elif output_file:
#         result_dataset = driver.Create(output_file, data20.shape[1],
#                                        data20.shape[0], sr20.shape[2],
#                                        gdal.GDT_Float64)
#         result_dataset.SetGeoTransform(ds20.GetGeoTransform())
#         result_dataset.SetProjection(ds20.GetProjection())
#     print(" the super-resolved bands in %s" % output_file)
#     for bi, bn in enumerate(validated_60m_bands):
#         write_band_data(sr20[:, :, bi], "SR" + validated_descriptions[bn],
#                         "SR" + bn)

# for desc in all_descriptions:
#     print(desc)

# CG added --->
for resID in ['10m', '20m', '60m']:
    print('resID = ' + str(resID))
    for desc in all_descriptions_croppedInput[resID]:
        print('  -> desc = ' + desc)
# <---

if args.output_file_format == "npz":
    # np.savez(output_file, bands=bands)
    # CG added --->
    np.savez(output_file_croppedInput['10m'], bands=bands_croppedInput['10m'])
    np.savez(output_file_croppedInput['20m'], bands=bands_croppedInput['20m'])
    np.savez(output_file_croppedInput['60m'], bands=bands_croppedInput['60m'])
    # <---

# if args.quality_assessment_mode:
#     print("Assessing the quality of the reconstruction from 40m data")
#     # Now compare the data in sr10 (actually at 20m, super-resolved from 40m)
#     # against the data in qam_ori20.
#     # Pixel-by-pixel computations are necessary => C++ implementation
#     indicators = sres.assess_quality(qam_ori20, sr10)
#     # indicators are Q, normalized MSE, SAM per row, one row per band
#     avg_Q = 1.
#     avg_MSE = 0.
#     avg_SAM = 0.
#     print("Band\tQ\tERGAS\tSAM")
#     for bi, bn in enumerate(validated_20m_bands):
#         print("%s\t%.3g\t%.3g\t%.3g" % (bn, indicators[bi, 0], 50 * math.sqrt(
#             indicators[bi, 1]), indicators[bi, 2]))
#         avg_Q *= indicators[bi, 0]
#         avg_MSE += indicators[bi, 1]
#         avg_SAM += indicators[bi, 2]
#     # Average computations
#     avg_Q = math.pow(avg_Q, 1. / len(validated_20m_bands))
#     avg_MSE /= len(validated_20m_bands)
#     avg_SAM /= len(validated_20m_bands)
#     print("Geometric average Q: %.3g" % avg_Q)
#     print("Overall ERGAS: %.3g" % (50 * math.sqrt(avg_MSE)))
#     print("Average SAM (degrees): %.3g" % avg_SAM)
