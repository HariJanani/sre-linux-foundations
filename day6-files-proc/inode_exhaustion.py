#!/usr/bin/env python3
import os, sys

def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: python3 inode_exhaustion.py <mount_directory>")
        
    target_dir = sys.argv[1]
    file_count = 0
    try:
        while True:
            file_path = os.path.join(target_dir, f"dummy_inode_{file_count}.txt")
            with open(file_path, "w") as f:
                pass
            file_count += 1
    except OSError as e:
        print(f"[EXHAUSTION FIRED] OS Error: {e}")

if __name__ == "__main__":
    main()
