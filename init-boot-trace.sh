#!/bin/bash
# Day 1 Lab: Linux Boot & Systemd Trace Script

echo "=== KERNEL BOOT PARAMETERS ==="
cat /proc/cmdline

echo -e "\n=== DEFAULT SYSTEMD TARGET ==="
systemctl get-default

echo -e "\n=== TOP 5 SLOWEST BOOT SERVICES ==="
systemd-analyze blame 2>/dev/null | head -n 5
