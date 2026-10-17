#!/usr/bin/env python3
import os
import time
import sys
import signal

def sigterm_handler(signum, frame):
    print(f"\n[SIGNAL HANDLER] Caught Signal {signum} (SIGTERM/SIGINT)! Cleaning up gracefully...")
    sys.exit(0)

signal.signal(signal.SIGTERM, sigterm_handler)
signal.signal(signal.SIGINT, sigterm_handler)

def main():
    print(f"[INITIAL] Process PID: {os.getpid()}, Parent PID (PPID): {os.getppid()}")
    
    try:
        pid = os.fork()
    except OSError as e:
        sys.exit(f"Fork failed: {e}")

    if pid == 0:
        print(f"[CHILD] Started. My PID: {os.getpid()}, Original Parent PID: {os.getppid()}")
        print("[CHILD] Sleeping for 6 seconds waiting to become orphaned...")
        
        for i in range(6):
            time.sleep(1)
            print(f"[CHILD] Tick {i+1}s | Current Parent PID (PPID): {os.getppid()}")
            
        print("[CHILD] Child execution complete.")
    else:
        print(f"[PARENT] Started. PID: {os.getpid()}, Created Child PID: {pid}")
        print("[PARENT] Parent exiting immediately (abandoning child)...")
        sys.exit(0)

if __name__ == "__main__":
    main()
