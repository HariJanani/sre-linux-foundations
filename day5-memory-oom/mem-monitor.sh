#!/bin/bash
# ==============================================================================
# SRE FOUNDATIONS - DAY 5 LAB: MEMORY & PAGE FAULT DIAGNOSTICS
# Author: HariJanani
# Repository: sre-linux-foundations
#
# PURPOSE:
# Inspects kernel memory allocation (/proc/meminfo), measures page fault 
# rates (minor vs major), and tunes OOM Killer score adjustments.
# ==============================================================================

LOGFILE="mem_lab_output.txt"

# COMMAND: echo "..." > $LOGFILE
# PURPOSE: Initializes the logfile with clean header metadata.
# REAL-WORLD SCENARIO: Prepares telemetry reports for automated pipeline validation.
echo "==================================================" > $LOGFILE
echo "   DAY 5 SRE LAB: MEMORY & OOM KILLER TELEMETRY   " >> $LOGFILE
echo "==================================================" >> $LOGFILE
echo "Execution Time: $(date)" >> $LOGFILE
echo "" >> $LOGFILE

# ------------------------------------------------------------------------------
# STEP 1: PARSING /proc/meminfo
# ------------------------------------------------------------------------------
# COMMAND: grep -E "MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree" /proc/meminfo
# PURPOSE: Extracts essential virtual memory fields directly from kernel interface.
# REAL-WORLD SCENARIO: Monitoring agents (Datadog/Prometheus) parse these fields to alert on RAM exhaustion.
echo "=== 1. CURRENT SYSTEM MEMORY BREAKDOWN (/proc/meminfo) ===" | tee -a $LOGFILE
grep -E "MemTotal|MemFree|MemAvailable|Buffers|^Cached|SwapTotal|SwapFree" /proc/meminfo >> $LOGFILE

# ------------------------------------------------------------------------------
# STEP 2: MEASURING PAGE FAULTS (sar -B)
# ------------------------------------------------------------------------------
# COMMAND: sar -B 1 3
# PURPOSE: Measures page fault dynamics:
#   - 'pgpgin/s'  : Kbytes paged in from disk (Major Page Fault activity).
#   - 'fault/s'   : Total page faults per second (Minor + Major).
#   - 'majflt/s'  : Major page faults per second (requires disk I/O, causes severe performance degradation).
# REAL-WORLD SCENARIO: High 'majflt/s' indicates the host is actively swapping or reading file blocks, destroying API latency.
echo -e "\n=== 2. PAGE FAULT RATE MONITORING (sar -B) ===" | tee -a $LOGFILE
sar -B 1 3 >> $LOGFILE 2>&1

# ------------------------------------------------------------------------------
# STEP 3: OOM SCORE ADJUSTMENT & SURVIVABILITY TUNING
# ------------------------------------------------------------------------------
# COMMAND: echo 500 > /proc/$PID/oom_score_adj
# PURPOSE: Adjusts process OOM likelihood. Valid values range from -1000 (Protected/Never Kill) to +1000 (First Priority Kill).
# REAL-WORLD SCENARIO: Kubernetes sets oom_score_adj based on Pod Quality of Service (QoS):
#   - Guaranteed Pods : -997 (Protected)
#   - BestEffort Pods : +1000 (Killed first during memory spikes)
echo -e "\n=== 3. DEMONSTRATING OOM SCORE TUNING ===" | tee -a $LOGFILE

# Start background dummy process
sleep 100 &
TEST_PID=$!

echo "Spawned Test Process PID: $TEST_PID" >> $LOGFILE
echo "Initial Kernel oom_score: $(cat /proc/$TEST_PID/oom_score)" >> $LOGFILE
echo "Initial Kernel oom_score_adj: $(cat /proc/$TEST_PID/oom_score_adj)" >> $LOGFILE

# Adjust oom_score_adj to make it high priority for OOM Kill
echo 500 > /proc/$TEST_PID/oom_score_adj

echo "Updated oom_score_adj to +500..." >> $LOGFILE
echo "New Kernel oom_score: $(cat /proc/$TEST_PID/oom_score)" >> $LOGFILE

# Clean up test process
kill -9 $TEST_PID 2>/dev/null

echo -e "\n==================================================" >> $LOGFILE
echo "Lab completed successfully. Telemetry saved to $LOGFILE" | tee -a $LOGFILE
