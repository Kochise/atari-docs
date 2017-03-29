#include <lib.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>

int raise(sig)
int sig;
{
  kill(getpid(), sig);
  return 0;
}
