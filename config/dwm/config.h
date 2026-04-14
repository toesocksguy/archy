/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const int refreshrate        = 120;      /* refresh rate for move/resize (Hz) */
static const char *fonts[]          = { "JetBrainsMono Nerd Font:size=10" };
static const char dmenufont[]       = "JetBrainsMono Nerd Font:size=10";
static const char col_gray1[]       = "#282828"; /* Gruvbox bg */
static const char col_gray2[]       = "#504945"; /* Gruvbox bg3 – inactive border */
static const char col_gray3[]       = "#ebdbb2"; /* Gruvbox fg1 – normal text */
static const char col_gray4[]       = "#fbf1c7"; /* Gruvbox fg0 – selected text */
static const char col_cyan[]        = "#fe8019"; /* Gruvbox orange – accent */
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_gray2, col_cyan  },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class      instance    title       tags mask     isfloating   isterminal   noswallow   monitor */
	{ "Gimp",     NULL,       NULL,       0,            1,           0,           0,          -1 },
	{ "Firefox",  NULL,       NULL,       1 << 8,       0,           0,          -1,          -1 },
	{ "kitty",    NULL,       NULL,       0,            0,           1,           0,          -1 },
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *termcmd[] = { "kitty", NULL };
static const char *roficmd[] = { "rofi", "-show", "drun", "-show-icons", NULL }; /* launch Rofi drun */
static const char *helpcmd[] = { "/bin/sh", "-c", "~/.config/dwm/scripts/keybindings.sh", NULL };
/* screenshots: maim saves to ~/Pictures/screenshots/ with a timestamp filename */
static const char *scrotcmd[]       = { "/bin/sh", "-c", "mkdir -p ~/Pictures/screenshots && maim -s ~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png", NULL }; /* Super+s: region select */
static const char *scrotfullcmd[]   = { "/bin/sh", "-c", "mkdir -p ~/Pictures/screenshots && maim ~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png", NULL };   /* Super+Shift+s: fullscreen */

static const Key keys[] = {
	/* modifier                     key        function        argument */

	/* launchers */
	{ MODKEY,                       XK_p,      spawn,          {.v = roficmd } },           /* Super+p: rofi app launcher */
        { MODKEY|ShiftMask,             XK_p,      spawn,          {.v = dmenucmd } },           /* Super+Shift+p: dmenu */
	{ MODKEY|ShiftMask,             XK_Return, spawn,          {.v = termcmd } },            /* Super+Shift+Enter: terminal */

	/* utilities */
	{ MODKEY|ShiftMask,             XK_w,      spawn,          SHCMD("feh --randomize --bg-fill ~/Pictures/wallpapers/*") }, /* Super+Shift+w: random wallpaper */
	{ MODKEY,                       XK_s,      spawn,          {.v = scrotcmd } },           /* Super+s: screenshot (region select) */
	{ MODKEY|ShiftMask,             XK_s,      spawn,          {.v = scrotfullcmd } },       /* Super+Shift+s: screenshot (fullscreen) */
	{ MODKEY|ShiftMask,             XK_h,      spawn,          {.v = helpcmd } },            /* Super+Shift+h: keybindings help */

	/* window management */
	{ MODKEY,                       XK_b,      togglebar,      {0} },                        /* Super+b: toggle bar */
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },                 /* Super+j: focus next window */
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },                 /* Super+k: focus prev window */
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },                 /* Super+i: increase master count */
	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },                 /* Super+d: decrease master count */
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },               /* Super+h: shrink master */
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },               /* Super+l: grow master */
	{ MODKEY,                       XK_Return, zoom,           {0} },                        /* Super+Enter: promote to master */
	{ MODKEY,                       XK_Tab,    view,           {0} },                        /* Super+Tab: toggle last tag */
	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },                        /* Super+Shift+c: close window */
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },                        /* Super+Shift+Space: toggle float */

	/* layouts */
	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },         /* Super+t: tile layout */
	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },         /* Super+f: float layout */
	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },         /* Super+m: monocle layout */
	{ MODKEY,                       XK_space,  setlayout,      {0} },                        /* Super+Space: toggle last layout */

	/* monitors */
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },                 /* Super+,: focus prev monitor */
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },                 /* Super+.: focus next monitor */
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },                 /* Super+Shift+,: move to prev monitor */
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },                 /* Super+Shift+.: move to next monitor */

	/* tags */
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },                /* Super+0: view all tags */
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },                /* Super+Shift+0: assign to all tags */
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)

	/* session */
	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },                        /* Super+Shift+q: quit dwm */
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};

