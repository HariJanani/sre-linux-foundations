#!/bin/bash
# ==============================================================================
# SRE FOUNDATIONS - DAY 4 LAB: CFS SCHEDULER & CPU AFFINITY DIAGNOSTICS
# Author: HariJanani
# Repository: sre-linux-foundations
#
# PURPOSE:
# Demonstrates Linux CFS scheduling, process CPU affinity pinning (taskset),
# nice value priority adjustments, and real-time preemption (chrt).
# ==============================================================================

LOGFILE="cfs_affinity_lab_output.txt"

# COMMAND: echo "..." > $LOGFILE
# PURPOSE: Initializes the log output file with execution environment details.
# REAL-WORLD SCENARIO: Prepares telemetry reports for automated pipeline validation.
echo "==================================================" > $LOGFILE
echo "   DAY 4 SRE LAB: CFS SCHEDULER & CPU AFFINITY    " >> $LOGFILE
echo "==================================================" >> $LOGFILE
echo "Execution Time: $(date)" >> $LOGFILE
echo "Available CPU Cores: $(nproc)" >> $LOGFILE
echo "" >> $LOGFILE

# ------------------------------------------------------------------------------
# STEP 1: PINNING WORKLOADS WITH CPU AFFINITY (taskset)
# ------------------------------------------------------------------------------
# COMMAND: taskset -c 0 stress-ng --cpu 1 --timeout 6s &
# PURPOSE: Binds a stress-ng worker strictly to logical CPU Core 0 using a mask/list (-c 0).
# REAL-WORLD SCENARIO: Used in low-latency infrastructure to bind critical application threads 
#                      to dedicated NUMA nodes or isolated CPU cores (isolcpus) to maximize L1/L2 cache hits.
echo "=== 1. TESTING CPU AFFINITY PINNING (taskset) ===" | tee -a $LOGFILE
echo "Spawning stress-ng worker pinned strictly to CPU Core 0..." | tee -a $LOGFILE

taskset -c 0 stress-ng --cpu 1 --timeout 6s >> $LOGFILE 2>&1 &
AFFINITY_PID=$!

sleep 1

# COMMAND: taskset -p $AFFINITY_PID
# PURPOSE: Queries the active CPU affinity mask for a running process ID.
# REAL-WORLD SCENARIO: SREs verify that high-throughput microservices stay pinned to 
#                      allocated CPU sets (e.g., Kubernetes cpumanager static policy).
echo -e "\n--- Verifying Active CPU Affinity Mask ---" | tee -a $LOGFILE
taskset -p $AFFINITY_PID >> $LOGFILE 2>&1

echo -e "\n--- Process Core Allocation Snapshot (mpstat) ---" | tee -a $LOGFILE
mpstat -P ALL 1 3 >> $LOGFILE 2>&1

wait $AFFINITY_PID

# ------------------------------------------------------------------------------
# STEP 2: CFS NICE VALUE PRIORITY ADJUSTMENT (nice / renice)
# ------------------------------------------------------------------------------
# COMMAND: nice -n 19 stress-ng ... vs nice -n -10 stress-ng ...
# PURPOSE: Launches two competing CPU tasks on Core 0 with opposing nice priorities (+19 lowest, -10 highest).
# REAL-WORLD SCENARIO: Ensures background batch processes (e.g., log compression, backups) run with high 
#                      nice values (+19) so they never starve low-latency user-facing API threads.
echo -e "\n==================================================" >> $LOGFILE
echo "=== 2. DEMONSTRATING CFS NICE PRIORITY CONTENTION ===" | tee -a $LOGFILE
echo "Launching Low Priority (+19) and High Priority (-10) tasks on Core 0..." | tee -a $LOGFILE

# Launch Low Priority task (Nice +19)
taskset -c 0 nice -n 19 stress-ng --cpu 1 --timeout 8s >> $LOGFILE 2>&1 &
LOW_PRIO_PID=$!

# Launch High Priority task (Nice -10)
taskset -c 0 nice -n -10 stress-ng --cpu 1 --timeout 8s >> $LOGFILE 2>&1 &
HIGH_PRIO_PID=$!

sleep 2

echo -e "\n--- Process Priority & CPU Distribution (ps) ---" | tee -a $LOGFILE
ps -o pid,ni,pri,pcpu,stat,comm -p $LOW_PRIO_PID,$HIGH_PRIO_PID >> $LOGFILE 2>&1

wait $LOW_PRIO_PID $HIGH_PRIO_PID

# ------------------------------------------------------------------------------
# STEP 3: REAL-TIME SCHEDULING PREEMPTION (chrt)
# ------------------------------------------------------------------------------
# COMMAND: chrt -f 50 stress-ng ...
# PURPOSE: Runs a task using SCHED_FIFO (Real-Time FIFO policy) at priority level 50.
# REAL-WORLD SCENARIO: Used for deterministic kernel daemons, network packet processing (DPDK),
#                      or audio/video processing engines that must immediately interrupt standard CFS tasks.
echo -e "\n==================================================" >> $LOGFILE
echo "=== 3. REAL-TIME SCHEDULER PREEMPTION (SCHED_FIFO via chrt) ===" | tee -a $LOGFILE
echo "Spawning Real-Time (SCHED_FIFO, Priority 50) task..." | tee -a $LOGFILE

taskset -c 0 chrt -f 50 stress-ng --cpu 1 --timeout 6s >> $LOGFILE 2>&1 &
RT_PID=$!

sleep 1

# COMMAND: chrt -p $RT_PID
# PURPOSE: Queries the active scheduling policy and real-time priority level of a process.
echo -e "\n--- Verifying Real-Time Scheduling Policy ---" | tee -a $LOGFILE
chrt -p $RT_PID >> $LOGFILE 2>&1

wait $RT_PID

echo -e "\n==================================================" >> $LOGFILE
echo "Lab completed successfully. Telemetry saved to $LOGFILE" | tee -a $LOGFILE
