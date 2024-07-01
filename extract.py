import sys
import os

lines = [5,9,10,18]


def extract(dir: str, out_filename: str, compressor: str, inp_filename: str, n_runs: int, decompress=False):
    PATH = f"output/{dir}/{'decompression_results' if decompress else 'info'}/{out_filename}"
    write_type = 'w' if not os.path.exists(PATH) else 'a'    
    
    with open(PATH, write_type) as out:
        if write_type == 'w':
            out.write('task-clock,cycles,instructions,time-elapsed\n')
        for i in range(1, n_runs+1):
            with open(f"{compressor}_info{i}_{inp_filename}", 'r') as f:
                for j, line in enumerate(f):
                    if j in lines:
                        out.write(line.strip().split()[0].replace(',', '.'))
                        out.write(',' if j != 18 else '\n')

if __name__ == '__main__':
    if len(sys.argv) == 6:
        extract(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5]))
    elif len(sys.argv) == 7:
        extract(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5]), decompress=True)
    else:
        print("Usage: python3 extract.py <dir> <out_filename> <compressor> <inp_filename> <n_runs> [decompress]")
        sys.exit(1)