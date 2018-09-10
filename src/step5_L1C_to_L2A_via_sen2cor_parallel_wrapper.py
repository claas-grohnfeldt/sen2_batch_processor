#!/urs/bin/env python3

#from multiprocessing import Pool
import multiprocessing as mp
import time
import subprocess
import os
import argparse

parser = argparse.ArgumentParser()
parser.add_argument(
    "--parallel",
    required=True,
    type=int,
    help="number of cores to be used for parallel processing.")
parser.add_argument(
    "--file_source_list",
    required=True,
    type=str,
    help="path to file containing list of L1C products to be processed to L2A via sen2cor")
parser.add_argument(
    "--file_L2A_Process",
    required=True,
    type=str,
    help="path to main sen2cor program")
parser.add_argument(
    '--remove_L1C_SAFE_folder',
    dest='remove_L1C_SAFE_folder', 
    action='store_true',
    required=True)

parser.set_defaults(remove_L1C_SAFE_folder=False)

args = parser.parse_args()

def call_sen2cor(PATH_DIR_TILE_L1C):
    subprocess.call(['bash', args.file_L2A_Process, PATH_DIR_TILE_L1C])
    if(args.remove_L1C_SAFE_folder):
        print("removing L1C SAFE folder '",PATH_DIR_TILE_L1C,"' ... ", end='')
        subprocess.call(['rm', '-r', PATH_DIR_TILE_L1C])
        print('done.')
    

if __name__ == '__main__':

    with open(args.file_source_list) as f:
        PATH_DIR_TILE_L1C_LIST = f.read().splitlines()

    start_time = time.time()
    
    print('Maximum number of cores available:', mp.cpu_count())
    if(args.parallel > mp.cpu_count()):
        print('using', mp.cpu_count(), 'cores')
        # Create a multiprocessing Pool
        pool = mp.Pool()
    else:
        print('using', args.parallel, 'cores')
        # Create a multiprocessing Pool
        pool = mp.Pool(args.parallel)
    
    # process data_inputs iterable with pool
    pool.map(call_sen2cor, PATH_DIR_TILE_L1C_LIST)
    time_period1 = time.time() - start_time
    print("time_period1:", time_period1)

