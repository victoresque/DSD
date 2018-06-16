## Baseline
  * Implementation
    * a module for each stage
  * Jump instructions
    * where: ID stage, similar to branch, if jump in later stages, more bubble cycles are generated
    * J: can be done in IF stage, but for convenience, we handle J in ID stage with other jump instructions
    * JR: need the correct value of the register, so forwarded values are needed
    * JAL/JALR: use control signals LinkRA and LinkRD to determine the link destination
  * Branch
    * without branch prediction, we handle BEQ in ID stage
    * note that BEQ also need the correct value of the register, so forwarded values are also needed
  * Stall conditions
    * add an additional module `stall_aggregator` which can stall stages from three stall signals
      * DCACHE_stall: DCACHE may stall when calling LW/SW
      * load_word_stall: when calling LW, a bubble is needed (for load-use hazard)
      * ICACHE_stall: ICACHE may stall when fetching instructions
    * Function (with order)
      1. if DCACHE_stall, stall IF/ID/EX
      2. if load_word_stall, stall IF/ID/EX, flush ID
      3. if ICACHE_stall, flush IF
  * Forwarding
    * since we handle BEQ in ID stage, we need to forward values to ID instead of EX
    * four possible forwarding (no forwarding, from EX, from MEM, from WB)
    * similar conditions with the addition of forwarding from EX
  * Cache
    * seperated design for ICACHE and DCACHE, no write operation needed for ICACHE
    * read preloader: not used in final design, little performance improvement, reasons:
      1. FSM: if k consecutive read + continuous address, then preload next address, many branch/jump in Final
      2. the slow_memory.v in Final behaves different from memory.v in HW4, which is much slower
        * HW4 tb: memory.v vs. slow_memory.v
  * **Experiments**
    1. AT curve
    2. compile/compile_ultra settings

## L2 Cache
  * Design
    * L1: 8 x 128
    * L2: 64 x 128
    * write buffer in write back design
  * **Experiments**
    * total clock cycles comparison under different size of tb_L2Cache
      1. no cache
      2. L1
      3. L1+L2
    * cycles under different size of L1/L2 cache size
    * area comparison under same clock speed constraint
    * hit/miss rate comparison

## Branch Prediction
  * Design
    * basically the same as in extension description
    * 2-bit saturating counter
  * **Experiments**
    * total clock cycles comparison under different configurations of tb_BrPred
    * area comparison under same clock speed constraint

## Multiplier/Divider
  * Design
    * multi-cycle multiplier/divider
    * new control signals: MFHI, MFLO
  * Details
    * signed multiplication: remembering sign for A and B
    * signed division: remebering sign for A and B, slightly different from the common remainder definition (positive)
  * **Experiments**
    * area and total clock cycles comparison under same clock speed constraint
      1. verilog arithmetics
      2. multi-cycle design (~32 cycles)
      3. barrel shifter design (~8 cycles) 
