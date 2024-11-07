#!/bin/bash

# Declare an array of block sizes to iterate over
#block_sizes=("4096" "8192" "16384" "32768" "65536" "131072" "262144" "524288" "1048576" "2097152" "4194304" "8388608" "16777216" "33554432")
block_sizes=("8388608" "16777216")

# Clear the /mnt/990 directory and drop caches before starting benchmarks
sudo rm -rf /mnt/990/*
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

# Iterate over each block size
echo "Starting benchmark for block sizes: ${block_sizes[*]}"

for block_size in "${block_sizes[@]}"
do
  # Run the benchmark 5 times for each block size
  # Clear the /mnt/990 directory and drop caches before each run
    sudo rm -rf /mnt/990/*
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

    for run in {1..2}
  do
    log_file="RWR(1k)-300sec_block(${block_size})_241030_run${run}.log"
    cmd="sudo ./db_bench -benchmarks=\"readwhilewriting,stats\" -db=/mnt/990 -level0_slowdown_writes_trigger=36 -level0_stop_writes_trigger=36 \
    -stats_interval_seconds=1 \
    -threads=1 -duration=300 -value_size=1024 \
    -max_write_buffer_number=8 -max_background_flushes=1 \
    -max_background_compactions=1 \
    -statistics -histogram -use_direct_io_for_flush_and_compaction=true \
    -disable_wal=true \
    -cache_size=0 \
    -compression_ratio=1.0 \
    -block_size=$block_size \
    "

    # Log the command being run and execute it
    echo "$cmd" | sudo tee "$log_file" > /dev/null
    echo "Running command for block size $block_size, iteration $run"
    sudo bash -c "$cmd" 2>&1 | sudo tee -a "$log_file" && wait

    # Wait for 10 seconds after each run
    sleep 10
  done
done

echo "Benchmark completed."
