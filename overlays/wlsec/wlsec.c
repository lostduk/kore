/* imports */
#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include <wayland-client.h>

#include "security-context-v1-client-protocol.h"

/* function declarations */
static void cloexec(int fd, int on);
static void die(const char *fmt, ...);
static void global(void *data, struct wl_registry *reg, uint32_t name,
		const char *iface, uint32_t version);
static void globalremove(void *data, struct wl_registry *reg, uint32_t name);

/* variables */
static struct wp_security_context_manager_v1 *mgr;
static const struct wl_registry_listener reglistener = {
	global, globalremove
};

/* function implementations */
void
cloexec(int fd, int on)
{
	if (fcntl(fd, F_SETFD, on ? FD_CLOEXEC : 0) < 0)
		die("fcntl:");
}

void
die(const char *fmt, ...)
{
	va_list ap;
	int saved;

	saved = errno;
	fputs("kore-wlsec: ", stderr);
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
	if (fmt[0] && fmt[strlen(fmt) - 1] == ':')
		fprintf(stderr, " %s", strerror(saved));
	fputc('\n', stderr);
	exit(1);
}

void
global(void *data, struct wl_registry *reg, uint32_t name, const char *iface,
		uint32_t version)
{
	if (!strcmp(iface, wp_security_context_manager_v1_interface.name))
		mgr = wl_registry_bind(reg, name,
				&wp_security_context_manager_v1_interface, 1);
}

void
globalremove(void *data, struct wl_registry *reg, uint32_t name)
{
}

/* main */
int
main(int argc, char *argv[])
{
	struct wl_display *dpy;
	struct wl_registry *reg;
	struct wp_security_context_v1 *ctx;
	struct sockaddr_un addr = { .sun_family = AF_UNIX };
	int fd, p[2];

	if (argc < 4) {
		fputs("usage: kore-wlsec socket app-id command [arg ...]\n", stderr);
		return 1;
	}
	if (strlen(argv[1]) >= sizeof(addr.sun_path))
		die("%s: socket path too long", argv[1]);
	strcpy(addr.sun_path, argv[1]);

	if (!(dpy = wl_display_connect(NULL)))
		die("cannot connect to the compositor");
	reg = wl_display_get_registry(dpy);
	wl_registry_add_listener(reg, &reglistener, NULL);
	if (wl_display_roundtrip(dpy) < 0)
		die("roundtrip:");
	if (!mgr)
		die("compositor has no security context manager");

	if ((fd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0)
		die("socket:");
	cloexec(fd, 1);
	if (unlink(argv[1]) < 0 && errno != ENOENT)
		die("unlink %s:", argv[1]);
	if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0)
		die("bind %s:", argv[1]);
	if (listen(fd, 128) < 0)
		die("listen:");
	if (pipe(p) < 0)
		die("pipe:");
	cloexec(p[0], 1);

	ctx = wp_security_context_manager_v1_create_listener(mgr, fd, p[0]);
	wp_security_context_v1_set_sandbox_engine(ctx, "org.lostduk.kore");
	wp_security_context_v1_set_app_id(ctx, argv[2]);
	wp_security_context_v1_commit(ctx);
	wp_security_context_v1_destroy(ctx);
	if (wl_display_roundtrip(dpy) < 0)
		die("security context refused:");
	wl_display_disconnect(dpy);
	close(fd);
	close(p[0]);

	/* keep p[1] open in the command: closing it stops the listener */
	cloexec(p[1], 0);
	execvp(argv[3], argv + 3);
	die("exec %s:", argv[3]);
	return 1;
}
