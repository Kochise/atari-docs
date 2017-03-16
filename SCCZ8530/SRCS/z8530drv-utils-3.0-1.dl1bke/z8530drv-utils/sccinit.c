/* 
	   sccinit.c - Initialize the z8530 SCC driver
   
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
#include <sys/socket.h>

#include "sccutils.h"

#define RCS_ID "$Id: sccinit.c,v 1.7 1995/11/17 01:10:17 jreuter Exp jreuter $"

struct cmds {
		char *name;
		int  token;
	    };
	    
#define I_DEVICE	0x80
#define I_MODE		0x81
#define I_CLOCK		0x82
#define I_SPEED		0x83
#define I_BOARD		0x84
#define I_CTRLPA	0x85
#define I_CTRLPB	0x86
#define I_DATAPA	0x87
#define I_DATAPB	0x88
#define I_ESCC		0x89
#define I_IRQ		0x8a
#define I_OPTION	0x8b
#define I_PCLOCK	0x8c
#define I_SPECIAL	0x8d
#define I_VECTOR	0x8e
#define I_CHIP		0x8f
#define I_BUFSIZE	0x90
#define I_RXBUFFERS	0x91
#define I_TXBUFFERS	0x92
#define I_WARN		0x93

#define P_OFF		-1
#define P_NULL		0
#define P_ON		1
#define P_YES		1
#define P_NRZ		4
#define P_NRZI		5
#define P_DEVICE	6
    
struct cmds clist[] =  {{"#",		0},
			{"board",	I_BOARD},
			{"bufsize",	I_BUFSIZE},
			{"chip",	I_CHIP},
			{"clocksrc",	I_CLOCK},
			{"ctrl_a",	I_CTRLPA},
			{"ctrl_b",	I_CTRLPB},
			{"data_a",	I_DATAPA},
			{"data_b",	I_DATAPB},
			{"device",	I_DEVICE},
			{"escc",	I_ESCC},
			{"fullduplex", 	PARAM_FULLDUP},
			{"group",	PARAM_GROUP},
			{"idletime",	PARAM_IDLE},
			{"irq",		I_IRQ},
			{"maxdefer",	PARAM_MAXDEFER},
			{"maxkeyup",	PARAM_MAXKEY},
			{"mintime",	PARAM_MIN},
			{"mode",	I_MODE},
			{"option",	I_OPTION},
			{"pclock",	I_PCLOCK},
			{"persistence",	PARAM_PERSIST},
			{"rxbuffers",	I_WARN},
			{"slottime",	PARAM_SLOTTIME},
			{"slip",	I_WARN},
			{"special",	I_SPECIAL},
			{"speed",	I_SPEED},
			{"softdcd",	PARAM_SOFTDCD},
			{"tailtime",	PARAM_TXTAIL},
			{"txbuffers",	I_WARN},
			{"txdelay",	PARAM_TXDELAY},
			{"txoff",	PARAM_TX},
			{"txtailtime",	PARAM_TXTAIL},
			{"vector",	I_VECTOR},
			{"waittime",	PARAM_WAIT},
			{"", 0}
};

struct cmds plist[] = {	{"divider",	CLK_DIVIDER},
			{"dpll",	CLK_DPLL},
			{"external",	CLK_EXTERNAL},
			{"no", 		P_OFF},
			{"normal",	CLK_DPLL},
			{"nrz",		P_NRZ},
			{"nrzi",	P_NRZI},
			{"off", 	P_OFF},
			{"on", 		P_ON}, 
			{"yes", 	P_ON},
			{"pa0hzp",      PA0HZP},
			{"eagle",	EAGLE},
			{"pc100",	PC100},
			{"primus",	PRIMUS},
			{"drsi",	DRSI},
			{"baycom",	BAYCOM},
			{"", 0}
};

char Board = 0;
io_port Vector = 0;
long Clock = 4915200;
int Irq = 0;

int parse_param(struct cmds *list, char *s)
{
	struct cmds *c;
	
	if (!*s) return 0;
	
	for (c = &list[0]; *(c->name) != '\0' ; c++)
	{
		if (!strncmp(s, c->name, strlen(s)))
			return c->token;
	}
	
	return -2;
}

#define IS_WHITESPACE(x) ((x == ' ') || (x == '\t'))

void scan_line(char *s, char *cmd, char *par)
{
	char *p, *q;
	char buf[256];
	int k, n;
	
	*cmd='\0';
	*par='\0';
	
	p=s; 
	while(*p)
	{
		*p=tolower(*p);
		p++;
	}
	
	for (p=s, k=0; k < 2; k++)
	{
		n = 0;
		
		while (*p)
		{
			if (!IS_WHITESPACE(*p)) break;
			p++;
		}
		
		if (!*p) return;
		
		q = p;
		
		while (*p)
		{
			if (IS_WHITESPACE(*p) || *p == '\n') break;
			p++; n++;
		}
		
		if (!n) return;
		
		n = (n>19? 19:n);
		strncpy(buf, q, n);
		buf[n] = '\0';
		
		strcpy(k? par:cmd, buf);
	}
}
		

#define ISDIGIT(x) ((x >= '0') && (x <= '9'))
#define WRNGPARA "sccinit(): wrong parameter '%s' to '%s' in line %u\n"

int main(int argc, char **argv)
{
	FILE *fp;
	int  fd;
	char s[80];
	char cmd[20];
	char val[20];
	char flag, hwinit;
	int  k, command, param;
	
	struct scc_modem modem;
	struct scc_hw_config hwcfg;
	struct scc_mem_config memcfg;
	struct scc_kiss_cmd kcmd;

	struct ifreq ifr;
	
	check_version();
	
	fp = fopen(CONFIGFILE,"r");
	fd = 0;
	flag = 1;
	hwinit = 1;
	
	memset(&hwcfg, 0, sizeof(hwcfg));
	memset(&memcfg, 0, sizeof(memcfg));
	memset(&modem, 0, sizeof(modem));
	
	fd = socket(AF_AX25, SOCK_DGRAM, 0);
	strcpy(ifr.ifr_name, "scc0");
	
	k = 0;
	
	while (!feof(fp))
	{
		k++;

		fgets(s, 255, fp);

		scan_line(s, cmd, val);
		if ((command = parse_param(clist, cmd)) < 0)
		{
			printf("sccinit(): unknown command %s in line %u\n", cmd, k);
			continue;
		}

		if (command == 0) continue;

		if (!*val)
		{
			printf("sccinit(): parameter is missing in line %u\n", k);
			continue;
		}		

		if (ISDIGIT(*val))
		{
			if (*(val+1) == 'x')
				sscanf(val, "%x", &param);
			else
				param = atoi(val);
		} else {
			param = parse_param(plist, val);

			if ((param < -1) && (command != I_DEVICE))
			{
				printf(WRNGPARA, val, cmd, k);
				continue;
			}
		}

		if (command == I_DEVICE)
		{		
			if (hwinit)
			{
				ifr.ifr_data = (caddr_t) &hwcfg;
				ioctl(fd, SIOCSCCCFG, &ifr);
				ifr.ifr_data = (caddr_t) &k;

				if (ioctl(fd, SIOCSCCINI, &ifr))
				{
					perror("SIOCSCCINI: ");
					exit(1);
				}

				hwinit = 0;
			}
			
			if (*val == '/')
				strcpy(ifr.ifr_name, val+5);
			else
				strcpy(ifr.ifr_name, val);
		}
		
		if (command == I_CLOCK)
		{
			switch (param)
			{
				case CLK_DPLL:
				case CLK_EXTERNAL:
				case CLK_DIVIDER: break;
				
				case P_OFF:	  param = CLK_DPLL; break;
				
				default:	printf(WRNGPARA, val, cmd, k);
					 	param=0;
					 	continue;
			}
		}
		
		if (command == I_MODE)
		{
			switch (param)
			{
				case P_NRZI:	param=0; break;
				case P_NRZ:	param=1; break;
				default: 	printf(WRNGPARA, val, cmd, k);
					 	param=0;
					 	continue;
			}
		}
		
		switch(param)
		{
			case P_OFF:
				switch(command)
				{
					case PARAM_MAXKEY:
					case PARAM_MIN:
					case PARAM_MAXDEFER:
					case PARAM_IDLE: param = TIMER_OFF; break;
					case PARAM_PERSIST: param = 255; break;
					default: param = 0;
				}
				break;
				
			case P_NULL:
				switch(command)
				{
					case PARAM_MAXKEY:
					case PARAM_MIN:
					case PARAM_MAXDEFER: param = TIMER_OFF; break;
				}
				break;
		}
		
		
		if (fd)
		{
			if (hwinit)
			{
				switch (command)
				{
					case I_CHIP:
						if (!flag)
						{
							ifr.ifr_data = (caddr_t) &hwcfg;
							if (ioctl(fd, SIOCSCCCFG, &ifr) < 0)
							{
								perror("FATAL: ioctl(SIOCSCCCFG) on scc0: ");
								fprintf(stderr,"Sccinit aborted\n");
								exit(1);
							}
						}
						

						memset(&hwcfg, 0, sizeof(hwcfg));
						hwcfg.irq = Irq;
						hwcfg.brand = Board;
						hwcfg.vector_latch = Vector;
						hwcfg.clock = Clock;
						flag = 0;
						
						break;
						
					case I_BOARD:
						Board = (char) param;
						hwcfg.brand = (char) param;
						break;
					case I_CTRLPA:
						hwcfg.ctrl_a = (io_port) param;
						break;
					case I_CTRLPB:
						hwcfg.ctrl_b = (io_port) param;
						break;
					case I_DATAPA:
						hwcfg.data_a = (io_port) param;
						break;
					case I_DATAPB:
						hwcfg.data_b = (io_port) param;
						break;
					case I_PCLOCK:
						hwcfg.clock = (long) param;
						break;
					case I_IRQ:
						Irq = (int) param;
						hwcfg.irq = Irq;
						break;
					case I_SPECIAL:
						hwcfg.special = (io_port) param;
						break;
					case I_OPTION:
						hwcfg.option = (char) param;
						break;
					case I_VECTOR:
						hwcfg.vector_latch = (io_port) param;
						break;
					case I_ESCC:
						hwcfg.escc = (char) param;
						break;
					default:
						/* error */
				}
			} else {
				switch (command)
				{
					case I_DEVICE: 
						flag = 0;
						memset(&modem, 0, sizeof(modem));
						break;
					
					case I_MODE:
						modem.nrz = (char) param;
						break;
						
					case I_CLOCK:
						modem.clocksrc = (char) param;
						break;
					
					case I_SPEED:
						modem.speed = (long) param;
						break;
						
					case I_BUFSIZE:
						memcfg.bufsize = (unsigned int) param;
						break;
					
					case I_WARN:
						fprintf(stderr, "Warning: parameter '%s' now unsupported\n", cmd);
						break;
					
					default:
						if (!flag)
						{
							if (!modem.speed) 
								modem.speed=1200;
							
							ifr.ifr_data = (caddr_t) &modem;
							ioctl(fd, SIOCSCCCHANINI, &ifr);
							
							if (!memcfg.bufsize)
								memcfg.bufsize = 384;
		
							ifr.ifr_data = (caddr_t) &memcfg;
							ioctl(fd, SIOCSCCSMEM, &ifr);
		
							memset(&memcfg, 0, sizeof(memcfg));
							flag = 1;
	
						}
						
						kcmd.command = command;
						kcmd.param = (long) param;
						
						ifr.ifr_data = (caddr_t) &kcmd;
						ioctl(fd, SIOCSCCSKISS, &ifr);
				}
			}
		} else {
			printf("no device: %s ignored",s);
		}
	}
	
	fclose(fp);
	return 0;
}
