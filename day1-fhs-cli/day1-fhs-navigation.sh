#!/bin/bash
# ==============================================================================
# SRE FOUNDATIONS - DAY 1 LAB: FHS NAVIGATION & OS ENVIRONMENT AUDIT
# Author: HariJanani
# Repository: sre-foundations
# ==============================================================================

LOGFILE="day1_lab_execution.log"

# Function to print clear headers and explain commands
run_step() {
    local step_title="$1"
    local explanation="$2"
    local command_to_run="$3"

    echo "======================================================================" | tee -a "$LOGFILE"
    echo "STEP: $step_title" | tee -a "$LOGFILE"
    echo "EXPLANATION: $explanation" | tee -a "$LOGFILE"
    echo "RUNNING COMMAND: $command_to_run" | tee -a "$LOGFILE"
    echo "----------------------------------------------------------------------" | tee -a "$LOGFILE"
    eval "$command_to_run" 2>&1 | tee -a "$LOGFILE"
    echo "" | tee -a "$LOGFILE"
}

# Clear previous log
> "$LOGFILE"
echo "Starting Day 1 Hands-On Lab Execution at $(date)" | tee -a "$LOGFILE"
echo "" | tee -a "$LOGFILE"

# ------------------------------------------------------------------------------
# 1. PWD (PRINT WORKING DIRECTORY)
# ------------------------------------------------------------------------------
run_step "1. Verify Initial Location with 'pwd'" \
"In production troubleshooting, you must always verify your current working directory to avoid issuing destructive commands in unintended directories." \
"pwd"

# ------------------------------------------------------------------------------
# 2. NAVIGATING /etc & INSPECTING CONFIGURATIONS
# ------------------------------------------------------------------------------
run_step "2. Navigate to /etc via Absolute Path" \
"We use an absolute path starting with '/' to move into /etc, the repository of static host configurations." \
"cd /etc && pwd"

run_step "3. View System Release & Hostname Configs" \
"SREs inspect /etc/os-release to determine the exact Linux distribution and kernel compatibility when debugging software issues." \
"cat /etc/os-release | grep -E '^(PRETTY_NAME|VERSION_ID)='"

run_step "4. Inspect DNS Nameserver Configuration" \
"/etc/resolv.conf defines where the host sends DNS lookup requests. Corrupted nameservers lead directly to network resolution failures." \
"cat /etc/resolv.conf | grep 'nameserver'"

# ------------------------------------------------------------------------------
# 3. RELATIVE PATH NAVIGATION & /var INSPECTION
# ------------------------------------------------------------------------------
run_step "5. Navigate from /etc to /var/log via Relative Path" \
"Using the relative navigation anchor '..' allows you to traverse up to root and down to /var/log without writing an absolute path." \
"cd ../var/log && pwd"

run_step "6. Inspect Log Directory Metadata with 'ls -lah'" \
"'ls -lah' displays hidden dot files (-a), permissions and ownership (-l), and human-readable file sizes (-h)." \
"ls -lah | head -n 12"

# ------------------------------------------------------------------------------
# 4. TOGGLE NAVIGATION WITH 'cd -'
# ------------------------------------------------------------------------------
run_step "7. Toggle to Previous Directory with 'cd -'" \
"'cd -' acts as an instantaneous toggle between your last two directories, essential for moving quickly between log locations and config directories." \
"cd - && pwd"

run_step "8. Return Back to /var/log with 'cd -'" \
"Toggling once more brings us straight back to /var/log." \
"cd - && pwd"

# ------------------------------------------------------------------------------
# 5. KERNEL & PROCESS INSPECTION IN /proc
# ------------------------------------------------------------------------------
run_step "9. Inspect CPU Architecture from Kernel Memory" \
"/proc/cpuinfo exposes raw CPU metrics directly from kernel memory. It consumes 0 bytes of physical disk space." \
"grep -m 1 'model name' /proc/cpuinfo && echo -n 'Total Logical Cores: ' && grep -c ^processor /proc/cpuinfo"

run_step "10. Inspect RAM State from /proc/meminfo" \
"/proc/meminfo gives granular memory telemetry. SREs look at 'MemAvailable', not 'MemFree', to evaluate memory saturation before OOM conditions trigger." \
"grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached):' /proc/meminfo"

run_step "11. Inspect the Shell Process Environment via /proc/self/environ" \
"/proc/self is a dynamic symlink to the process currently reading it. Environment variables are stored as null-byte ('\0') separated strings, so we translate them to newlines." \
"cat /proc/self/environ | tr '\0' '\n' | grep -E '^(PATH|USER|HOME|SHELL)='"

# ------------------------------------------------------------------------------
# 6. HARDWARE & CGROUPS INSPECTION IN /sys
# ------------------------------------------------------------------------------
run_step "12. Inspect Cgroups v2 & Storage Interfaces in /sys" \
"/sysfs exposes physical device properties and control group limits used by Docker and Kubernetes to restrict memory and CPU." \
"ls -d /sys/fs/cgroup /sys/block /sys/class/net"

run_step "13. Return Home with 'cd ~' and Verify Final Location" \
"Using '~' immediately takes you to your user's home directory regardless of your current position in the filesystem tree." \
"cd ~ && pwd"

echo "======================================================================" | tee -a "$LOGFILE"
echo "Day 1 Hands-On Lab Execution Completed Successfully!" | tee -a "$LOGFILE"
echo "All outputs and telemetry logged to: $LOGFILE" | tee -a "$LOGFILE"
echo "======================================================================" | tee -a "$LOGFILE"
