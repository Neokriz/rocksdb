log_file="FR(1k)-num(10240000x1)_RA(0MB)_1027-5.log" && \
cmd="./db_bench -benchmarks="fillrandom,stats" -db=/mnt/990 -level0_slowdown_writes_trigger=36 -level0_stop_writes_trigger=36 \
-stats_interval_seconds=1 \
-threads=1 -num=10240000 -value_size=1024 \
-max_write_buffer_number=2 -max_background_flushes=1 \
-max_background_compactions=1 \
-statistics -histogram -use_direct_io_for_flush_and_compaction=true \
-disable_wal=true \
-compression_ratio=0.0 \
-cache_size=0 \
-compaction_readahead_size=0  \
" && \
echo $cmd 1> $log_file && \
sudo stdbuf -o 0 $cmd 2>&1 | tee -a $log_file
