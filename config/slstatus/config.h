/* See LICENSE file for copyright and license details. */

/* interval between updates (in ms) */
const unsigned int interval = 1000;

/* text to show if no value can be retrieved */
static const char unknown_str[] = "n/a";

/* maximum output string length */
#define MAXLEN 2048

static const struct arg args[] = {
	/* function   format          argument */
	{ cpu_perc,   " CPU %s%% |",  NULL },
	{ ram_perc,   " MEM %s%% |",  NULL },
	{ wifi_essid, " %s |",        "wlan0" },
	{ datetime,   " %s ",         "%H:%M" },
};
