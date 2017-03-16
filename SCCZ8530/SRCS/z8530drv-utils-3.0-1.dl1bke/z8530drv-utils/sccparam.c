/* 
	   sccparam.c - Set Z8530 SCC driver parameters

   Copyright 1994-1996, by Joerg Reuter dl1bke@lykos.oche.de

   This program is intended for Amateur Radio use. If you are running it
   for commercial purposes, please drop me a note. I am nosy...

   ! You  m u s t  recognize the appropriate legislations of your country !
   ! before you connect a radio to the SCC board and start to transmit or !
   ! receive. The GPL allows you to use the  d r i v e r,  NOT the RADIO! !

   For non-Amateur-Radio use please note that you might need a special
   allowance/licence from the designer of the SCC Board and/or the
   MODEM. 

   This program is free software; you can redistribute it and/or modify 
   it under the terms of the (modified) GNU General Public License 
   delivered with the LinuX kernel source.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should find a copy of the GNU General Public License in 
   /usr/src/linux/COPYING; 

*/

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <termios.h>
#include <string.h>
#include <ctype.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <linux/timer.h>
#ifdef CONFIG_SCC_STANDALONE
#include "scc.h"
#else
#include <linux/scc.h>
#endif
#include <linux/fs.h>
#include <linux/tty.h>
#include <linux/if.h>

#include "sccutils.h"

#define RCS_ID "$Id: sccparam.c,v 1.7 1995/11/17 01:10:47 jreuter Exp jreuter $"


struct cmds {
		char *name;
		int  token;
	    };
	    
#define	C_BUFSIZE	0x80
#define C_RXBUFFERS	0x81
#define C_TXBUFFERS	0x82
	    
struct cmds clist[] =  {{"bufsize",	C_BUFSIZE},
			{"fullduplex", 	PARAM_FULLDUP},
			{"group",	PARAM_GROUP},
			{"idletime",	PARAM_IDLE},
			{"maxdefer",	PARAM_MAXDEFER},
			{"maxkeyup",	PARAM_MAXKEY},
			{"mintime",	PARAM_MIN},
			{"persistence",	PARAM_PERSIST},
			{"slottime",	PARAM_SLOTTIME},
			{"speed",	PARAM_SPEED},
			{"softdcd",	PARAM_SOFTDCD},
			{"tailtime",	PARAM_TXTAIL},
			{"txdelay",	PARAM_TXDELAY},
			{"txoff",	PARAM_TX},
			{"txtailtime",	PARAM_TXTAIL},
			{"waittime",	PARAM_WAIT},
			{"", 0}
};

struct cmds plist[] = {{"no", -1}, {"off", -1}, {"normal", -1},
		       {"on", 1}, {"yes", 1}, {"hwctrl", 1}, {"", 0}};
		       
int parse_param(struct cmds *list, char *s)
{
	struct cmds *c;
	
	for (c = &list[0]; *(c->name) != '\0' ; c++)
	{
		if (!strncmp(s, c->name, strlen(s)))
			return c->token;
	}
	
	return -2;
}

void handle_error(int error, char *op, char *par)
{
	char buf[30];
	
	switch(error)
	{
		case -ENODATA:
			fprintf(stderr,"Error: parameter %s not supported\n", par);
			exit(1);
		case -ENODEV:
			fprintf(stderr,"Error: Channel not attached\n");
			exit(1);
		default:
			sprintf(buf, "Error: ioctl() failed on %s", op);
			perror(buf);
			exit(1);
	}
}
	

#define ISDIGIT(x) ((x >= '0') && (x <= '9'))
int main(int argc, char **argv)
{
	int fd;
	int param, val;
	struct scc_kiss_cmd cmd;
	struct scc_stat stat;
	struct scc_mem_config memcfg;
	int error;
	struct ifreq ifr;
	
	check_version();

	if (argc < 3)
	{
		fprintf(stderr, "\nusage: %s dev param [value]\n", argv[0]);
		fprintf(stderr, "example: %s scc1 txdelay 20\n\n", argv[0]);
		exit(1);
	}
	
	fd = socket(AF_AX25, SOCK_DGRAM, 0);
	strcpy(ifr.ifr_name, argv[1]);
	ifr.ifr_data = (caddr_t) &stat;

	if (ioctl(fd, SIOCSCCGSTAT, &ifr) < 0)
	{
		perror("ERROR: Cannot get device\n");
		exit(1);
	}

	if (ISDIGIT(*argv[2]))
	{
		param=atoi(argv[2]);
		
	} else {
	
		if ((param = parse_param(clist, argv[2])) < 0)
		{
			fprintf(stderr,"error: unknown command %s\n",argv[2]);
			exit(1);
		}
	}
	
	
	if (argc < 4)
	{
		if (param < 0x80)
		{
			cmd.command = param;
			
			ifr.ifr_data = (caddr_t) &cmd;
			error = ioctl(fd, SIOCSCCGKISS, &ifr);
		
			if (error < 0) 
				handle_error(error, "SIOCSCCGKISS", argv[2]);
			if (cmd.param == NO_SUCH_PARAM) 
				handle_error(-ENODATA, "SIOCSCCGKISS", argv[2]);
		
			printf("%s %u\n", argv[2], cmd.param);
		}
	} else {
		if (ISDIGIT(*argv[3]))
		{
			if (*(argv[3]+1) == 'x')
				sscanf(argv[3], "%x", &val);
			else
				val = atoi(argv[3]);
		} else {
			val = parse_param(plist, argv[3]);
			
			if (val < -1)
			{
				fprintf(stderr,"error: wrong parameter %s ", argv[3]);
				exit(1);
			}
		}
		
			
		if (val < 0)
		{
			switch(param)
			{
				case PARAM_MAXKEY:
				case PARAM_MIN:
				case PARAM_MAXDEFER:
				case PARAM_IDLE: val = TIMER_OFF; break;
				case PARAM_PERSIST: val = 255; break;
				default: val = 0;
			}
		}
		else if (val == 0)
		{
			switch(param)
			{
				case PARAM_MAXKEY:
				case PARAM_MIN:
				case PARAM_MAXDEFER: val = TIMER_OFF; break;
			}
		}
		
		if (param >= 0x80)
		{
			ifr.ifr_data = (caddr_t) &stat;
			error = ioctl(fd, SIOCSCCGSTAT, &ifr);

			if (error < 0)
			{
				perror("Can't get channel status: ");
				exit(1);
			}
			
			memcfg.bufsize  = stat.bufsize;
			
			switch(param)
			{
				case C_BUFSIZE:
					memcfg.bufsize = val;
					break;
			}
			
			ifr.ifr_data = (caddr_t) &memcfg;
			error = ioctl(fd, SIOCSCCSMEM, &ifr);
			
			if ( error < 0) handle_error(error, "SIOCSCCSMEM", "");
		} else {		
			cmd.command = param;
			cmd.param = val;
		
			ifr.ifr_data = (caddr_t) &cmd;
			error = ioctl(fd, SIOCSCCSKISS, &ifr);

			if (error < 0) handle_error(error, "SIOCSCCSKISS", argv[2]);
		}
	}
				
	close(fd); 
	return 0;
}
