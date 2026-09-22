#include <fcntl.h>
#include <dirent.h>

static int statussig;
pid_t statuspid = -1;

pid_t
getstatusbarpid(void)
{
	char buf[64], *str = buf, *c;
	FILE *fp;

	if (statuspid > 0) {
		snprintf(buf, sizeof(buf), "/proc/%u/cmdline", (unsigned int)statuspid);
		if ((fp = fopen(buf, "r"))) {
			if (fgets(buf, sizeof(buf), fp)) {
				while ((c = strchr(str, '/')))
					str = c + 1;
				fclose(fp);
				if (!strcmp(str, STATUSBAR))
					return statuspid;
			} else {
				fclose(fp);
			}
		}
	}

	/* Fast path: read PID file from $XDG_RUNTIME_DIR or /tmp (Zero-Fork) */
	const char *runtime_dir = getenv("XDG_RUNTIME_DIR");
	if (runtime_dir && runtime_dir[0]) {
		snprintf(buf, sizeof(buf), "%s/dwmblocks.pid", runtime_dir);
	} else {
		snprintf(buf, sizeof(buf), "/tmp/dwmblocks-%d.pid", getuid());
	}

	int fd = open(buf, O_RDONLY);
	if (fd >= 0) {
		ssize_t n = read(fd, buf, sizeof(buf) - 1);
		close(fd);
		if (n > 0) {
			buf[n] = 0;
			pid_t pid = (pid_t)strtol(buf, NULL, 10);
			if (pid > 0) {
				snprintf(buf, sizeof(buf), "/proc/%u/cmdline", (unsigned int)pid);
				if ((fp = fopen(buf, "r"))) {
					str = buf;
					if (fgets(buf, sizeof(buf), fp)) {
						while ((c = strchr(str, '/')))
							str = c + 1;
						fclose(fp);
						if (!strcmp(str, STATUSBAR)) {
							statuspid = pid;
							return statuspid;
						}
					} else {
						fclose(fp);
					}
				}
			}
		}
	}

	/* Fallback: scan /proc directly without popen or subshells */
	DIR *dir = opendir("/proc");
	if (dir) {
		struct dirent *ent;
		while ((ent = readdir(dir))) {
			if (ent->d_name[0] >= '0' && ent->d_name[0] <= '9') {
				snprintf(buf, sizeof(buf), "/proc/%s/cmdline", ent->d_name);
				if ((fp = fopen(buf, "r"))) {
					str = buf;
					if (fgets(buf, sizeof(buf), fp)) {
						while ((c = strchr(str, '/')))
							str = c + 1;
						fclose(fp);
						if (!strcmp(str, STATUSBAR)) {
							statuspid = (pid_t)strtol(ent->d_name, NULL, 10);
							closedir(dir);
							return statuspid;
						}
					} else {
						fclose(fp);
					}
				}
			}
		}
		closedir(dir);
	}

	return -1;
}

void
sigstatusbar(const Arg *arg)
{
	union sigval sv;

	if (!statussig)
		return;
	if ((statuspid = getstatusbarpid()) <= 0)
		return;

	sv.sival_int = arg->i;
	sigqueue(statuspid, SIGRTMIN+statussig, sv);
}

void
volume_change(const Arg *arg)
{
	pid_t pid = fork();
	if (pid == 0) {
		if (dpy)
			close(ConnectionNumber(dpy));
		setsid();
		int devnull = open("/dev/null", O_RDWR);
		if (devnull >= 0) {
			dup2(devnull, STDIN_FILENO);
			dup2(devnull, STDOUT_FILENO);
			dup2(devnull, STDERR_FILENO);
			close(devnull);
		}
		if (arg->i == 0) {
			execlp("wpctl", "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle", (char *)NULL);
		} else if (arg->i > 0) {
			char step[16];
			snprintf(step, sizeof(step), "%d%%+", arg->i);
			execlp("wpctl", "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", step, (char *)NULL);
		} else {
			char step[16];
			snprintf(step, sizeof(step), "%d%%-", -arg->i);
			execlp("wpctl", "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", step, (char *)NULL);
		}
		_exit(127);
	}

	/* Direct statusbar signaling: 0 pkill, 0 /proc scan */
	pid_t sb_pid = getstatusbarpid();
	if (sb_pid > 0) {
		sigqueue(sb_pid, SIGRTMIN + 11, (union sigval){.sival_int = 0});
	}
}
