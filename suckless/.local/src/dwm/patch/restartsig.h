#include <signal.h>

extern volatile sig_atomic_t reload_xrdb;
static void sighup(int unused);
static void sigterm(int unused);
static void sigusr1(int unused);

