#include <sys/prctl.h>
#include <signal.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

FILE *child_stdout = 0;

const int BUFF = 2048;
const short DOTS_LENGTH = 3;
const short TOTAL_VISIBLE_LEN = 96;
const short MIN_HEAD_LEN = 10;

void create_child(int sig) {
    wait(-1);
    child_stdout = popen("xmobar /home/janmejay/.xmonad/xmobarrc", "w");
}

void tweek_for_visibility(char buff[]) {
    int end = strlen(buff);
    if (end > TOTAL_VISIBLE_LEN) {
        short prefix_len = MIN_HEAD_LEN + DOTS_LENGTH;
        strcpy(buff + prefix_len, buff + (end - (TOTAL_VISIBLE_LEN - prefix_len)));
        int i;
        for(i = 0; i < DOTS_LENGTH; i++) {
            buff[MIN_HEAD_LEN + i] = '.';
        }
    }
}

int main(int argc, char** argv) {
    prctl(PR_SET_PDEATHSIG, SIGHUP);
    signal(SIGCHLD, create_child);
    create_child(0);
    char line[BUFF + 1];

    while(1) {
        if (fgets(line, BUFF, stdin) > 0) {
            tweek_for_visibility(line);
            fputs(line, child_stdout);
            fflush(child_stdout);
        }
    }
    return 0;
}
