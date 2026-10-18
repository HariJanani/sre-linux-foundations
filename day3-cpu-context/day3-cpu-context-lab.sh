#!/bin/bash
# ==============================================================================
# SRE FOUNDATIONS - DAY 3 LAB: CPU STRESS & CONTEXT SWITCH DIAGNOSTICS
# Author: HariJanani
# Repository: sre-linux-foundations
#
# PURPOSE:
# Demonstrates Linux CPU scheduling, Voluntary vs. Involuntary Context Switching,
# and CPU core saturation using stress-ng, pidstat, and vmstat.
# ==============================================================================

LOGFILE="cpu_context_lab_output.txt"

# COMMAND: echo "..." > $LOGFILE
# PURPOSE: Overwrites/creates the logfile with a clean header.
# REAL-WORLD SCENARIO: CI/CD test runners initialize clean log files for every deployment run.
echo "==================================================" > $LOGFILE
echo "   DAY 3 SRE LAB: CPU & CONTEXT SWITCH TELEMETRY  " >> $LOGFILE
echo "==================================================" >> $LOGFILE
echo "Execution Time: $(date)" >> $LOGFILE
echo "Total CPU Cores Available: $(nproc)" >> $LOGFILE
echo "" >> $LOGFILE

# ------------------------------------------------------------------------------
# STEP 1: BASELINE IDLE SYSTEM TELEMETRY
# ------------------------------------------------------------------------------
# COMMAND: vmstat 1 3
# PURPOSE: Displays virtual memory and CPU thread statistics every 1 second, 3 times.
# KEY METRICS TO OBSERVE:
#   - 'r'  : Run-Queue (number of tasks waiting for CPU execution time).
#   - 'cs' : System-wide Context Switches per second.
# REAL-WORLD SCENARIO: Used in automated monitoring scripts to establish baseline health 
#                      before applying system load or triggering an upgrade.
echo "=== 1. BASELINE SYSTEM METRICS (IDLE) ===" | tee -a $LOGFILE
echo "--- vmstat Baseline (3 seconds) ---" >> $LOGFILE
vmstat 1 3 >> $LOGFILE

# ------------------------------------------------------------------------------
# STEP 2: CPU COMPUTATION STRESS & INVOLUNTARY CONTEXT SWITCHES
# ------------------------------------------------------------------------------
# COMMAND: stress-ng --cpu 8 --cpu-method matrix --timeout 10s &
# PURPOSE: Spawns 8 intensive CPU matrix computation workers for 10 seconds in background.
# REAL-WORLD SCENARIO: Simulates heavy algorithmic processing (e.g., machine learning inference,
#                      data compression, high-volume encryption/TLS handshakes).
echo -e "\n=== 2. STRESSING CPU CORES & CAPTURING INVOLUNTARY CONTEXT SWITCHES ===" | tee -a $LOGFILE
echo "Spawning 8 CPU-bound stress-ng threads on a $(nproc)-core machine for 10s..." | tee -a $LOGFILE

stress-ng --cpu 8 --cpu-method matrix --timeout 10s >> $LOGFILE 2>&1 &
STRESS_PID=$!

sleep 2

# COMMAND: pidstat -w -p $STRESS_PID 1 3
# PURPOSE: Tracks task-level context switches for a specific PID every 1 second, 3 times.
# KEY METRIC: 'nvcswch/s' (Non-Voluntary / Involuntary Context Switches per second).
# REAL-WORLD SCENARIO: When a multi-threaded app (like Java/Go) exceeds its CPU quota,
#                      the Linux scheduler forcibly preempts it, spiking 'nvcswch/s'.
echo -e "\n--- Process-Level Context Switches (stress-ng PID $STRESS_PID) ---" | tee -a $LOGFILE
pidstat -w -p $STRESS_PID 1 3 >> $LOGFILE 2>&1

echo -e "\n--- System-Wide CPU & Context Switch Impact (vmstat) ---" | tee -a $LOGFILE
vmstat 1 4 >> $LOGFILE

wait $STRESS_PID

# ------------------------------------------------------------------------------
# STEP 3: HIGH VOLUNTARY CONTEXT SWITCHES (THREAD YIELDING)
# ------------------------------------------------------------------------------
# COMMAND: stress-ng --schedyield 16 --timeout 10s &
# PURPOSE: Forces 16 threads to repeatedly yield CPU execution time back to the kernel scheduler.
# REAL-WORLD SCENARIO: Simulates heavy lock contention, DB connection pool waiting, or microservices
#                      thrashing on high I/O blocking calls.
echo -e "\n==================================================" >> $LOGFILE
echo "=== 3. GENERATING HIGH VOLUNTARY CONTEXT SWITCHES (I/O & SCHEDULING) ===" | tee -a $LOGFILE
echo "Spawning 16 yield-stressor workers for 10s..." | tee -a $LOGFILE

stress-ng --schedyield 16 --timeout 10s >> $LOGFILE 2>&1 &
YIELD_PID=$!

sleep 2

# COMMAND: pidstat -w -p $YIELD_PID 1 3
# KEY METRIC: 'cswch/s' (Voluntary Context Switches per second).
# REAL-WORLD SCENARIO: High 'cswch/s' indicates threads are voluntarily giving up CPU time 
#                      because they are waiting for network sockets, disk I/O, or locks.
echo -e "\n--- Process-Level Voluntary vs. Involuntary Switches ---" | tee -a $LOGFILE
pidstat -w -p $YIELD_PID 1 3 >> $LOGFILE 2>&1

echo -e "\n--- System-Wide Impact of Yield Stressors (vmstat) ---" | tee -a $LOGFILE
vmstat 1 4 >> $LOGFILE

wait $YIELD_PID

echo -e "\n==================================================" >> $LOGFILE
echo "Lab completed successfully. Telemetry saved to $LOGFILE" | tee -a $LOGFILE
