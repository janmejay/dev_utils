#include <time.h>
#include <string.h>
#include <stdlib.h>
#include <pwd.h>
#include <unistd.h>
#include <utmp.h>

int
main(int argc, char *argv[])
{
  struct utmp entry;

  system("echo before adding entry:;who");

  entry.ut_type = USER_PROCESS;
  entry.ut_pid = getpid();
  strcpy(entry.ut_line, ttyname(STDIN_FILENO) + strlen("/dev/"));
  /* only correct for ptys named /dev/tty[pqr][0-9a-z] */
  strcpy(entry.ut_id, ttyname(STDIN_FILENO) + strlen("/dev/tty"));
  time(&entry.ut_time);
  strcpy(entry.ut_user, "janmejay");
  memset(entry.ut_host, 0, UT_HOSTSIZE);
  entry.ut_addr = 0;
  setutent();
  pututline(&entry);

  system("echo after adding entry:;who");

  endutent();
  exit(EXIT_SUCCESS);
}
