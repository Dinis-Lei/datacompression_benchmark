#!/bin/sh

display_usage() { 
	echo -e "Usage: $0 [OPTIONS] \n"
    echo -e "Options:\n"
    echo -e "\t-f FILENAME: File with copressors information to run"
    echo -e "\t-h: Display usage and exit"
    echo -e "\t-r N_RUNS: Number of runs to execute"
    echo -e "\t-t TEST_TYPE: Type of test to run\n"    
} 

isValid=(true true true)
n_runs=1
test_type="image"
test_extension="fasta"

while getopts 'f:hr:t:' OPTION; do
  case "$OPTION" in
    f)
        file=$OPTARG
        isValid[0]=false
        ;;
    h)
        display_usage
	    exit 0
        ;;
    r)
        n_runs=$OPTARG
        isValid[1]=false
        ;;
    t)
        test_type=$OPTARG
        isValid[2]=false
        ;;
    ?)
        echo "script usage: $(basename \$0) [-l] [-h]" >&2
        exit 1
        ;;
  esac
done

shift "$(($OPTIND -1))"

for element in "${isValid[@]}"; do
    if [ "$element" = true ]; then
        echo "Error."
        exit 0  # Exit with success status
    fi
done


compressors=()
flags=()
suffixes=()
has_output=()


while IFS="," read -r name alias arguments suffix output
do
    compressors+=($alias)
    flags+=("$arguments")
    suffixes+=($suffix)
    has_output+=($output)
done < <(tail -n +2 $file)


# compressors=("gzip" "zstd" "bzip2" "lzma" "paq8" "nncp")
# flags=("-k" "-k -q" "-k" "-k" "-1" "c")
# suffixes=("gz" "zst" "bz2" "lzma" "paq8n" "nncp")
# has_output=(false false false false false true)
# compressors=("nncp")
# flags=("c")
# suffixes=("nncp")
# has_output=(true)

echo START compressors: ${compressors[@]}
mkdir -p output/$test_type/compressed_files

# rm -rf output/$test_type/info
mkdir -p output/$test_type/info
# Iterate compressors and flags using size of compressors
for j in ${!compressors[@]}
do    
    compressor=${compressors[$j]}
    flag=${flags[$j]}
    suffix=${suffixes[$j]}
    # Iterate files in folder
    for file in input/$test_type/*
    do
        # get file name
        filename=$(basename $file)
       

        if [ $compressor = "paq8" ] && ([ $filename = "1000Mb.txt" ])
        then
            continue
        fi
        if [ $compressor = "nncp" ] && ([ $filename = "1000Mb.txt" ] || [ $filename = "100Mb.txt" ] || [ $filename = "12Mb.tif" ])
        then
            continue
        fi
        


        for i in $(seq 1 $n_runs)
        do
            statfile="${compressor}_info${i}_${filename}"

            if [ ${has_output[$j]} = true ]
            then
                outputfile=$file.$suffix
            else
                outputfile=""
            fi
            echo "Processing $i $filename with $compressor $flag $outputfile"
            if [ $compressor = "spring" ]
            then
                perf stat -o $statfile -d $compressor $flag -i $file -o $outputfile
                echo "spring"
            elif [ $compressor = "ennaf" ] || [ $compressor = "agc" ]
            then
                echo "Processing $i $filename with $compressor $flag $outputfile $file"
                perf stat -o $statfile -d $compressor $flag $outputfile $file
            else
                perf stat -o $statfile -d $compressor $flag $file $outputfile
                echo "A"
            fi
            mv $file.$suffix output/$test_type/compressed_files/
        done
        python3 extract.py $test_type ${compressor}_$filename $compressor $filename $n_runs
        for i in $(seq 1 $n_runs)
        do 
            rm ${compressor}_info${i}_${filename}
        done
    done
done
