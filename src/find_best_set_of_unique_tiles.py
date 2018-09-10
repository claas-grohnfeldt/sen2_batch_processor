##!/usr/bin/env python3

import pandas as pd
import numpy as np
import argparse
import datetime as dt

parser = argparse.ArgumentParser(description='Input needed to load information from correct directory.')
parser.add_argument('targetDir', help="Path to target directory into which the sentonel products corresponding to the current ROI should be downloaded. This folder must contain a subfolder 'aux' containing a non-empty file named 'candidate_tiles.csv'.")
parser.add_argument('maxNumDates', type=int, help="Maximum number of dates (products) per tile ID.")

args = parser.parse_args()
def fnct_rec(cur_list, opt_list, cur_opt, kTile, numTiles, df):
    if(kTile == numTiles):
        if(len(cur_list) != numTiles):
            raise Exception('ERROR: len(cur_list) must be equal to numTiles')
            #exit 1
        mysum = dt.timedelta(0)
        for k in range(numTiles-1):
            for l in range(k+1, numTiles):
                mysum += abs(df.at[k, cur_list[k]] - df.at[l, cur_list[l]])
        if(mysum < cur_opt):
            cur_opt = mysum
            opt_list = cur_list
        return (cur_opt, opt_list)
    else:
        numDates = df.at[kTile,'# dates']
        kTile += 1
        for r in range(numDates):
            new_list = cur_list + ['date ' + str(r)]
            tmp = fnct_rec(new_list, opt_list, cur_opt, kTile, numTiles, df)
            cur_opt = tmp[0]
            opt_list = tmp[1]
        return (cur_opt, opt_list)


def main():
    fname_tiles_info = args.targetDir + '/tiles_info.csv'
    fname_adjList = args.targetDir + '/aux/adjacency_lists.csv'
    parse_dates = []
    for k in range(args.maxNumDates):
        parse_dates = parse_dates + ['date ' + str(k)]
    df_adjList = pd.read_csv(fname_adjList, skipinitialspace=True, parse_dates=parse_dates)
    print('Before selection:')
    print(df_adjList)

    cur_list = []
    opt_list = []
    cur_opt = dt.timedelta(9999)
    kTile = 0
    dates = df_adjList.loc[:,'date 0':]
    numTiles = dates.shape[0]

    tmp = fnct_rec(cur_list, opt_list, cur_opt, kTile, numTiles, df_adjList)
    cur_opt = tmp[0]
    opt_list = tmp[1]
    print('')
    print('opt list (mutually closest dates) = ', opt_list)

    # without date formatting
    for kTile in range(df_adjList.shape[0]):
        df_adjList.at[kTile, 'date 0'] = df_adjList.at[kTile, opt_list[kTile]]

    df_adjList = df_adjList.drop('# dates', axis=1)
    for idate in range(1, args.maxNumDates):
        df_adjList = df_adjList.drop('date ' + str(idate), axis=1)

    df_adjList = df_adjList.rename(index=str, columns={"date 0": "date"})
    print('')
    print('After selection:')
    print(df_adjList)
    df_adjList.to_csv(fname_tiles_info, index=False, header=False)


if __name__ == "__main__":
    # execute only if run as a script
    main()
