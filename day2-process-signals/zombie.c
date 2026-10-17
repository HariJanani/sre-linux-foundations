#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

int main() {
    pid_t child_pid = fork();

    if (child_pid < 0) {
        perror("Fork failed");
        exit(1);
    }

    if (child_pid == 0) {
        printf("[CHILD] PID %d: I am exiting now...\n", getpid());
        exit(0);
    } else {
        printf("[PARENT] PID %d: Created Child PID %d\n", getpid(), child_pid);
        printf("[PARENT] Sleeping for 10 seconds WITHOUT calling wait()...\n");
        
        sleep(10);
        
        printf("[PARENT] Waking up! Calling wait() to reap child PID %d...\n", child_pid);
        wait(NULL);
        printf("[PARENT] Child reaped successfully. Exiting parent.\n");
    }

    return 0;
}
