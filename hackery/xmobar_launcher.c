#include <sys/prctl.h>
#include <signal.h>
#include <stdio.h>
#include <unistd.h>

FILE *child_stdout = 0;

const int BUFF = 2048;

void create_child(int sig) {
    wait(-1);
    child_stdout = popen("xmobar /home/janmejay/.xmonad/xmobarrc", "w");
}

int main(int argc, char** argv) {
    prctl(PR_SET_PDEATHSIG, SIGHUP);
    signal(SIGCHLD, create_child);
    create_child(0);
    char line[BUFF + 1];

    while(1) {
        if (fgets(line, BUFF, stdin) > 0) {
            fputs(line, child_stdout);
            fflush(child_stdout);
        }
    }
    return 0;
}
