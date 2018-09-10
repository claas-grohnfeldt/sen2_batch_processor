#!/urs/bin/env python3

#from multiprocessing import Pool
import multiprocessing as mp
import time
import subprocess

# def process_image(name):
#     time.sleep(1)
#     #print(name, end=' ')
#     #sci=fits.open('{}.fits'.format(name))
#     #<process>

def call_sen2cor(PATH_DIR_TILE_L1C):
    #PATH_FILE_L2A_Process = "src/thirdparties/sen2cor/bin/L2A_Process"    
    subprocess.call(['bash', './src/thirdparties/sen2cor/bin/L2A_Process', PATH_DIR_TILE_L1C])    

if __name__ == '__main__':

    #-----------------------------
    # should become program arguments:
    PATH_FILE_LIST_SEN2COR_TO_BE_PROCESSED='/home/ga39yoz/data/projects/sen2_batch_processor/tmp/sen2core_to_be_processed_180906_130557.txt'
    numProc = 10
    #numProc = 'all'
    #-----------------------------

    

    print('#cpus (mp) =', mp.cpu_count())
    data_inputs = [k for k in range(80)]

    with open(PATH_FILE_LIST_SEN2COR_TO_BE_PROCESSED) as f:
        PATH_DIR_TILE_L1C_LIST = f.read().splitlines()

    print(data_inputs)
    start_time = time.time()
    if(numProc == 'all'):
        pool = mp.Pool()                         # Create a multiprocessing Pool
    else:
        pool = mp.Pool(numProc)                  # Create a multiprocessing Pool
    
    # print(PATH_DIR_TILE_L1C_LIST) 
    #pool.map(process_image, data_inputs)  # process data_inputs iterable with pool
    pool.map(call_sen2cor, PATH_DIR_TILE_L1C_LIST)  # process data_inputs iterable with pool
    time_period1 = time.time() - start_time
    print("time_period1:", time_period1)

