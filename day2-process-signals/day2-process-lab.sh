#!/bin/bash
# Day 2 SRE Lab: Process Lifecycle, Zombie/Orphan Tracing, and Signal Trapping

LOGFILE="process_lab_output.txt"
echo "==================================================" > $LOGFILE
echo "   DAY 2 SRE LAB: PROCESS LIFECYCLE DIAGNOSTICS   " >> $LOGFILE
echo "==================================================" >> $LOGFILE
echo "Execution Time: $(date)" >> $LOGFILE
echo "" >> $LOGFILE

echo "=== 1. DEMONSTRATING ZOMBIE PROCESS (STATE Z) ===" | tee -a $LOGFILE
./zombie >> $LOGFILE 2>&1 &

sleep 3
echo -e "\n--- Process Status Output (Looking for 'Z' State) ---" | tee -a $LOGFILE
ps aux | head -n 1 >> $LOGFILE
ps aux | grep -E "Z|defunct" | grep -v grep >> $LOGFILE 2>&1

sleep 8
echo -e "\n--- Process Status After Parent Reaps Child ---" | tee -a $LOGFILE
ps aux | grep zombie | grep -v grep >> $LOGFILE 2>&1 || echo "Zombie reaped successfully from process table." | tee -a $LOGFILE

echo -e "\n==================================================" >> $LOGFILE
echo "=== 2. DEMONSTRATING ORPHAN PROCESS & RE-PARENTING ===" | tee -a $LOGFILE
python3 orphan.py >> $LOGFILE 2>&1

echo -e "\n==================================================" >> $LOGFILE
echo "=== 3. DEMONSTRATING SIGNAL TRAPPING (SIGTERM) ===" | tee -a $LOGFILE

python3 -c '
import signal, time, sys, os
def handler(s, f):
    print(f"[SIGNAL TRAPPED] Received SIGTERM on PID {os.getpid()}! Graceful exit.")
    sys.exit(0)
signal.signal(signal.SIGTERM, handler)
print(f"[APP] Running service on PID {os.getpid()}...")
sys.stdout.flush()
while True:
    time.sleep(1)
' >> $LOGFILE 2>&1 &

APP_PID=$!
sleep 2

echo "Sending SIGTERM (kill -15) to Application PID $APP_PID..." | tee -a $LOGFILE
kill -15 $APP_PID
sleep 1

echo -e "\n==================================================" >> $LOGFILE
echo "Lab completed. Output saved to $LOGFILE" | tee -a $LOGFILE
