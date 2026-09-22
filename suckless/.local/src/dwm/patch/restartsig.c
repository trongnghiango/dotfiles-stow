static int restart = 0;
volatile sig_atomic_t reload_xrdb = 0;

void
sighup(int unused)
{
	reload_xrdb = 1;
}

void
sigusr1(int unused)
{
	Arg a = {.i = 1};
	quit(&a);
}

void
sigterm(int unused)
{
	Arg a = {.i = 0};
	quit(&a);
}

