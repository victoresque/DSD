. read-only ICACHE
. comparison: read preloader (cycles)
. comparison (optional): memory.v and slow_memory.v (HW4 tb, cycles)
* baseline synthesis AT curve (area, speed)
. comparison: no cache/+I/+D/+I+D/+I+L2D/+L2I+L2D (cycles)
. comparison: L2 cache size (cycles, hit/miss rate, hit/miss penalty)
* comparison: no cahce/L1/L1+L2 (area, fix speed)
* comparison: different nb of tbBrPred with/without branch prediction (cycles, accuracy)
* comparison: with/without branch prediction (area, fix speed)
. comparison: arithmetics/multi-cycle/8-cycle (cycles, area, fix speed)


* Note
  * cycle 3.6, compile_ultra, tb 3.8
  * cycle 2.9, compile_ultra -retime, tb 3.6
  * cycle 3.7, compile, tb 4.4