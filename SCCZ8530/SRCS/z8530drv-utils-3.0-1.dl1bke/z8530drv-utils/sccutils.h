#define PROCFILE "/proc/net/z8530drv"
#define CONFIGFILE "/etc/z8530drv.conf"

#define VERSION "z8530drv-3.0\n"

static inline void check_version(void)
{
	FILE *fp = fopen(PROCFILE,"r");
	char buf[1024];
	
	if (fp == NULL)
	{
		fprintf(stderr,"sccinit: Warning, is z8530drv really loaded?\n");
		return;
	}

	fgets(buf, sizeof(buf), fp);
	if (strcmp(buf, VERSION))
	{
		fprintf(stderr,"sccinit: Warning, this program is for "
			VERSION", the driver is %s\n", buf);
	}
	fclose(fp);
}
