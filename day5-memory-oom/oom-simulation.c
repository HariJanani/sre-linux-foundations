/*
 * SRE FOUNDATIONS - DAY 5 LAB: OOM KILLER SIMULATOR
 * Author: HariJanani
 * Repository: sre-linux-foundations
 *
 * PURPOSE:
 * Continuously allocates physical RAM in 20 MB chunks and touches every 4KB page
 * to force real RSS expansion until the Linux kernel OOM killer fires.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define CHUNK_SIZE_MB 20
#define CHUNK_BYTES (CHUNK_SIZE_MB * 1024 * 1024)

int main() {
    long long total_allocated_mb = 0;
    printf("[OOM SIMULATOR] Starting memory allocation loop (PID: %d)...\n", getpid());
    printf("[OOM SIMULATOR] Inspect /proc/%d/oom_score and /proc/%d/oom_score_adj!\n", getpid(), getpid());

    while (1) {
        // Allocate virtual memory block
        char *ptr = (char *)malloc(CHUNK_BYTES);

        if (ptr == NULL) {
            perror("[OOM SIMULATOR] malloc failed (Virtual Memory Limit Reached)");
            sleep(1);
            continue;
        }

        // CRITICAL STEP: Touch every 4 KB page to trigger actual Physical Page Allocations (RSS expansion)
        for (size_t i = 0; i < CHUNK_BYTES; i += 4096) {
            ptr[i] = 'A';
        }

        total_allocated_mb += CHUNK_SIZE_MB;
        printf("[OOM SIMULATOR] Allocated and dirtied: %lld MB RAM\n", total_allocated_mb);

        // Brief delay to allow monitoring tools to capture telemetry
        usleep(100000); // 100ms
    }

    return 0;
}
