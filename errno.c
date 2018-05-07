#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: errno <error number>\n");
        return 1;
    }
    int err_num = atoi(argv[1]);
    char* err = strerror(err_num);
    printf("%d: %s\n", err_num, err);
    return 0;
}
