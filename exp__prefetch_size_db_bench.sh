#!/bin/bash

# Declare an array of block sizes to iterate over
block_sizes=("4096" "8192" "16384" "32768" "65536" "131072" "262144" "524288" "1048576" "2097152" "4194304" "8388608" "16777216" "33554432")
#block_sizes=("65536" "262144"  "8388608" "1677216" "33554432")

#prefetch_sizes=("4096" "8192" "16384" "32768" "65536" "131072" "262144" "524288" "1048576" "2097152" "4194304" "8388608" "16777216" "33554432")
prefetch_sizes=("0" "67108864")

# Clear the /mnt/990 directory and drop caches before starting benchmarks
sudo rm -rf ./DB_dir/*
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

# Iterate over each block size
echo "-----------------------------------------------------------------------"
echo "Starting benchmark for prefetch sizes: ${prefetch_sizes[*]}"
echo "-----------------------------------------------------------------------"

#for block_size in "${block_sizes[@]}"
for run in {1..1}
do
  # Run the benchmark 3 times for each block size
  # Clear the DB_dir directory and drop caches before each run
  sudo rm -rf ./DB_dir/* 
  sleep 10

  echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
  sleep 10

  #for run in {1..3}
  #for block_size in "${block_sizes[@]}"
  for prefetch_size in "${prefetch_sizes[@]}"
  do
    #log_file="./exp_logs/FR(1KB)-300sec_block(${block_size})_241224_run${run}.log"
    log_file="./exp_logs/FR(1KB)-300sec_prefetch(${prefetch_size})_241225_run${run}.log" # # # # #
    cmd="sudo ./base_db_bench -benchmarks=\"fillrandom,stats\" \
    -db=./DB_dir/ \
    -level0_slowdown_writes_trigger=36 \
    -level0_stop_writes_trigger=36 \
    -stats_interval_seconds=1 \
    -threads=1 \
    -max_write_buffer_number=8 \
    -duration=300 \
    -value_size=1024 \
    -max_background_flushes=1 \
    -max_background_compactions=1 \
    -statistics -histogram \
    -use_direct_io_for_flush_and_compaction=true \
    -use_direct_reads=true \
    -disable_wal=true \
    -cache_size=0 \
    -compression_ratio=1.0 \
    -compaction_readahead_size=$prefetch_size \
    -block_size=4096
    "
    #-block_size=$block_size \
    #-compaction_readahead_size=0 \
    #-writable_file_max_buffer_size=4096

    DB_log_="./exp_logs/FR(1KB)-300sec_prefetch(${prefetch_size})_241225_run${run}.LOG" # # # # #
    # Log the command being run and execute it
    echo "$cmd" | sudo tee "$log_file" > /dev/null
    echo "Running command for prefetch size $prefetch_sizes, iteration $run"
    sudo bash -c "$cmd" 2>&1 | sudo tee -a "$log_file" && wait

    sudo cp ./DB_dir/LOG "$DB_log_"
    # Wait for 30 seconds after each run
    sleep 30
  done
done

echo "Benchmark completed."

echo "-----------------------------------------------------------------------"
