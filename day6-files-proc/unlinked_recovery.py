#!/usr/bin/env python3
import os, time, sys

def main():
    pid = os.getpid()
    filename = "critical_application.log"
    print(f"[PROCESS] Running with PID: {pid}")
    
    filepath = os.path.abspath(filename)
    f = open(filepath, "w+")
    f.write("CRITICAL DATA: Log entry created before file unlinking event.\n")
    f.write("RECOVERY DATA: This payload must be recovered via /proc filesystem.\n")
    f.flush()
    
    fd_num = f.fileno()
    proc_fd_path = f"/proc/{pid}/fd/{fd_num}"
    print(f"[KERNEL] Assigned File Descriptor: FD {fd_num}")
    print(f"[PROC] Process FD Link Path: {proc_fd_path}")
    
    os.unlink(filepath)
    print(f"[UNLINK] File '{filename}' unlinked from directory entry.")
    
    f.write("POST-UNLINK DATA: Written after directory unlinking!\n")
    f.flush()
    
    time.sleep(15)
    f.close()

if __name__ == "__main__":
    main()
