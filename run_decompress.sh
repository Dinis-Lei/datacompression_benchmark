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

while IFS="," read -r name alias arguments suffix has_output
do
    compressors+=($alias)
    flags+=("$arguments")
    suffixes+=($suffix)
    has_outputs+=($has_output)
done < <(tail -n +2 $file)

mkdir -p output/$test_type/decompression_results

for j in ${!compressors[@]}
do    
    compressor=${compressors[$j]}
    flag=${flags[$j]}
    suffix=${suffixes[$j]}
    has_output=${has_outputs[$j]}
    # Iterate files in folder
    for file in output/$test_type/compressed_files/*.${suffix}
    do
        # get file name
        filename=$(basename $file)
        decompressed_filename=${filename%.*}
        echo $decompressed_filename
        echo FILE: $file

        for i in $(seq 1 $n_runs)
        do
            statfile="${compressor}_info${i}_${filename}"

            echo "Processing $i $filename with $compressor $flag $file"

            if [ "$has_output" = true ]; then
                if [ "$compressor" = "dsrc" ]; then
                    echo $compressor $flag $file output/$test_type/compressed_files/$decompressed_filename
                    perf stat -o $statfile -d $compressor $flag $file output/$test_type/compressed_files/$decompressed_filename
                elif [ "$compressor" = "spring" ]; then
                    decompressed_filename=$filename.d
                    echo $compressor $flag -i $file -o output/$test_type/compressed_files/$decompressed_filename
                    perf stat -o $statfile -d $compressor $flag -i $file -o output/$test_type/compressed_files/$decompressed_filename
                elif [ "$compressor" = "fqzcomp" ]; then
                    decompressed_filename=$filename.d
                    echo $compressor $flag -i $file -o output/$test_type/compressed_files/$decompressed_filename
                    perf stat -o $statfile -d $compressor $flag $file output/$test_type/compressed_files/$decompressed_filename
                else
                    decompressed_filename=$filename.d
                    echo $compressor $flag $decompressed_filename $file
                    perf stat -o $statfile -d $compressor $flag output/$test_type/compressed_files/$decompressed_filename $file
                fi
            else
                echo $compressor $flag $file
                perf stat -o $statfile -d $compressor $flag $file
                if [ "$compressor" = "MFCompressD" ]; then
                    decompressed_filename=$filename.d
                fi

            fi
            
            rm output/$test_type/compressed_files/$decompressed_filename
        done
        python3 extract.py $test_type ${compressor}_$decompressed_filename $compressor $filename $n_runs true
        for i in $(seq 1 $n_runs)
        do 
            rm ${compressor}_info${i}_${filename}
        done
    done
done