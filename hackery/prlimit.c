#define _GNU_SOURCE
#define _FILE_OFFSET_BITS 64
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/resource.h>

#define errExit(msg)                            \
    do { perror(msg); exit(EXIT_FAILURE);       \
    } while (0)



/* RLIMIT_AS */
/* RLIMIT_CORE */
/* RLIMIT_CPU */
/* RLIMIT_DATA */
/* RLIMIT_FSIZE */
/* RLIMIT_LOCKS */
/* RLIMIT_MEMLOCK */
/* RLIMIT_MSGQUEUE */
/* RLIMIT_NICE */
/* RLIMIT_NOFILE */
/* RLIMIT_NPROC */
/* RLIMIT_RSS */
/* RLIMIT_RTPRIO */
/* RLIMIT_RTTIME */
/* RLIMIT_SIGPENDING */
/* RLIMIT_STACK */

#define IS(name, val)                           \
    strcmp(name, val) == 0

int resource_for(const char* name) {
    if (IS(name, "address_space")) {
        return RLIMIT_AS;
    } else if (IS(name, "core")) {
        return RLIMIT_CORE;
    } else if (IS(name, "cpu")) {
        return RLIMIT_CPU;
    } else if (IS(name, "data")) {
        return RLIMIT_DATA;
    } else if (IS(name, "filesz")) {
        return RLIMIT_FSIZE;
    } else if (IS(name, "locks")) {
        return RLIMIT_LOCKS;
    } else if (IS(name, "memlock")) {
        return RLIMIT_MEMLOCK;
    } else if (IS(name, "msgqueue")) {
        return RLIMIT_MSGQUEUE;
    } else if (IS(name, "nice")) {
        return RLIMIT_NICE;
    } else if (IS(name, "fds")) {
        return RLIMIT_NOFILE;
    } else if (IS(name, "procs")) {
        return RLIMIT_NPROC;
    } else if (IS(name, "rss")) {
        return RLIMIT_RSS;
    } else if (IS(name, "rtprio")) {
        return RLIMIT_RTPRIO;
    } else if (IS(name, "rt-time")) {
        return RLIMIT_RTTIME;
    } else if (IS(name, "sig-pending")) {
        return RLIMIT_SIGPENDING;
    } else if (IS(name, "stack")) {
        return RLIMIT_STACK;
    } else {
        errExit("unknown resource identifier given");
    }
}

#define UNLIMITED "unlimited"

int
main(int argc, char *argv[])
{
    struct rlimit old, new;
    struct rlimit *newp;

    int get_limit = (argc == 3);
    int set_limit = (argc == 5);

    if (!(get_limit || set_limit)) {
        fprintf(stderr, "Usage: %s <pid> <resource>"
                "[<new-soft-limit> <new-hard-limit>]\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    pid_t pid = atoi(argv[1]);

    const char* resource_name = argv[2];

    int resource = resource_for(resource_name);

    newp = NULL;
    if (argc == 5) {
        if (IS(argv[3], UNLIMITED)) {
            new.rlim_cur = -1;
        } else {
            new.rlim_cur = atoi(argv[3]);
        }
        if (IS(argv[4], UNLIMITED)) {
            new.rlim_max = -1;
        } else {
            new.rlim_max = atoi(argv[4]);
        }
        newp = &new;
    }

    if (prlimit(pid, resource, newp, &old) == -1)
        errExit("prlimit-1");

    printf("Limits (%s): soft=%lld; hard=%lld\n",
           resource_name,
           (long long) old.rlim_cur,
           (long long) old.rlim_max);

    if (get_limit) return 0;

    if (prlimit(pid, resource, NULL, &old) == -1)
        errExit("prlimit-2");

    printf("Modified to (%s): soft=%lld; hard=%lld\n",
           resource_name,
           (long long) old.rlim_cur,
           (long long) old.rlim_max);

    exit(EXIT_FAILURE);
}
