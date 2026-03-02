/* general */
#define TAGCOUNT (6)

static int log_level                       = WLR_ERROR;
static const int sloppyfocus               = 1;
static const int bypass_surface_visibility = 0;

/* appearance */
static const unsigned int borderpx         = 1;
static const float rootcolor[]             = {0.1f, 0.1f, 0.1f, 1.0f};
static const float bordercolor[]           = {0.2f, 0.2f, 0.2f, 1.0f};
static const float focuscolor[]            = {0.0f, 0.3f, 0.4f, 1.0f};
static const float urgentcolor[]           = {0.1f, 0.0f, 0.0f, 1.0f};
static const float fullscreen_bg[]         = {0.1f, 0.1f, 0.1f, 1.0f};

/* rules */
static const Rule rules[] = {
	{ "Gimp_EXAMPLE", NULL, 0, 1, -1 },
};

/* layouts */
static const Layout layouts[] = {
	{ "[T]", tile },
	{ "[F]", NULL },
	{ "[M]", monocle },
};

/* monitors */
static const MonitorRule monrules[] = {
	{ NULL, 0.55f, 1, 1, &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, -1, -1 },
};

/* keyboard */
static const int repeat_rate = 25;
static const int repeat_delay = 600;

static const struct xkb_rule_names xkb_rules = {
	.layout = "us,th",
	.options = "grp:alt_shift_toggle",
};


/* trackpad */
static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 1;
static const int natural_scrolling = 0;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;

static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
static const double accel_speed = 0.0;
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

/* commands */
#define MODKEY WLR_MODIFIER_LOGO
#define MODALT WLR_MODIFIER_ALT
#define MODCTRL WLR_MODIFIER_CTRL
#define MODSHIFT WLR_MODIFIER_SHIFT

#define TAGKEYS(KEY, SKEY, TAG) \
	{ MODKEY, KEY, view, {.ui = 1 << TAG} }, \
	{ MODKEY|MODCTRL, KEY, toggleview, {.ui = 1 << TAG} }, \
	{ MODKEY|MODSHIFT, SKEY, tag, {.ui = 1 << TAG} }, \
	{ MODKEY|MODCTRL|MODSHIFT, SKEY, toggletag, {.ui = 1 << TAG} }

#define CHVT(n) { MODCTRL|MODALT, XKB_KEY_XF86Switch_VT_##n, chvt, {.ui = (n)} }

static const char *termcmd[] = { "foot", NULL };
static const char *menucmd[] = { "dmenu_run", NULL };

static const Key keys[] = {
	{ MODKEY, XKB_KEY_d, spawn, {.v = menucmd} },
	{ MODKEY, XKB_KEY_Return, spawn, {.v = termcmd} },
	{ MODKEY, XKB_KEY_j, focusstack, {.i = +1} },
	{ MODKEY, XKB_KEY_h, setmfact, {.f = -0.05f} },
	{ MODKEY, XKB_KEY_l, setmfact, {.f = +0.05f} },
	{ MODKEY, XKB_KEY_i, incnmaster, {.i = +1} },
	{ MODKEY, XKB_KEY_o, incnmaster, {.i = -1} },
	{ MODKEY, XKB_KEY_k, focusstack, {.i = -1} },
	{ MODKEY, XKB_KEY_q, killclient, {0} },
	{ MODKEY|MODSHIFT, XKB_KEY_Tab, view, {0} },
	{ MODKEY|MODSHIFT, XKB_KEY_Return, zoom, {0} },
	{ MODKEY|MODSHIFT, XKB_KEY_T, setlayout, {.v = &layouts[0]} },
	{ MODKEY|MODSHIFT, XKB_KEY_F, setlayout, {.v = &layouts[1]} },
	{ MODKEY|MODSHIFT, XKB_KEY_M, setlayout, {.v = &layouts[2]} },
	{ MODKEY, XKB_KEY_space, togglefloating, {0} },
	{ MODKEY, XKB_KEY_f, togglefullscreen, {0} },
	{ MODKEY, XKB_KEY_comma, focusmon, {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY, XKB_KEY_period, focusmon, {.i = WLR_DIRECTION_RIGHT} },
	{ MODKEY|MODSHIFT, XKB_KEY_less, tagmon, {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY|MODSHIFT, XKB_KEY_greater, tagmon, {.i = WLR_DIRECTION_RIGHT} },
	{ MODKEY|MODSHIFT, XKB_KEY_P, quit, {0} },

	/* Ctrl-Alt-Backspace and Ctrl-Alt-Fx used to be handled by X server */
	{ MODCTRL|MODALT, XKB_KEY_Terminate_Server, quit, {0} },

	TAGKEYS(XKB_KEY_1, XKB_KEY_exclam, 0),
	TAGKEYS(XKB_KEY_2, XKB_KEY_at, 1),
	TAGKEYS(XKB_KEY_3, XKB_KEY_numbersign, 2),
	TAGKEYS(XKB_KEY_4, XKB_KEY_dollar, 3),
	TAGKEYS(XKB_KEY_5, XKB_KEY_percent, 4),
	TAGKEYS(XKB_KEY_6, XKB_KEY_asciicircum, 5),

	/* Ctrl-Alt-Fx is used to switch to another VT */
	CHVT(1), CHVT(2), CHVT(3), CHVT(4), CHVT(5), CHVT(6),
	CHVT(7), CHVT(8), CHVT(9), CHVT(10), CHVT(11), CHVT(12),
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT, moveresize, {.ui = CurMove} },
	{ MODKEY, BTN_RIGHT, moveresize, {.ui = CurResize} },
	{ MODKEY, BTN_MIDDLE, togglefloating, {0} },
};
