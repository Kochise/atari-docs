/* 
	   sccstat.c - Get Z8530 SCC driver statistics
   
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
#include <fcntl.h>
#include <termios.h>
#include <strings.h>
#include <ctype.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/timer.h>
#ifdef CONFIG_SCC_STANDALONE
#include "scc.h"
#else
#include <linux/skbuff.h>
#include <linux/scc.h>
#endif
#include <linux/fs.h>
#include <linux/tty.h>
#include <linux/if.h>
#include <linux/errno.h>

#include "sccutils.h"

#define RCS_ID "$Id: sccstat.c,v 1.9 1995/11/17 01:10:36 jreuter Exp jreuter $"

struct ifreq ifr;
struct scc_stat stat;

const char * get_tx_status(int tx_state)
{
	switch(tx_state)
	{
		case	TXS_IDLE:
			return "idle";
			break;
		case	TXS_BUSY:
			return "busy";
			break;
		case	TXS_ACTIVE:
			return "active";
			break;
		case	TXS_NEWFRAME:
			return "kick";
			break;
		case	TXS_IDLE2:
			return "keyed";
			break;
		case	TXS_WAIT:
			return "wait";
			break;
		case	TXS_TIMEOUT:
			return "timeout";
	}

	return "?";
}

void print_param(int fd, char *name, char *form, int command)
{
	struct scc_kiss_cmd kiss_cmd;
	char s[80];
	int error;
	
	kiss_cmd.command = command;
	
	ifr.ifr_data = (caddr_t) &kiss_cmd;
	error = ioctl(fd, SIOCSCCGKISS, &ifr);
	
	if (error == 0)
	{
		if (*form == '*')
		{
			printf("%-12s: %s", name, kiss_cmd.param? "on":"off");
		} else {
			if (kiss_cmd.param == TIMER_OFF)
				printf("%-12s: off\n", s);
			else
			{
				sprintf(s, "%-12s: ", name);
				strcat(s, form);
				printf(s, kiss_cmd.param);
			}
		}
	}
	
	printf("\n");
}



void print_statistics(int fd)
{
	printf("\nParameters:\n\n");
	
	print_param(fd, "speed",	"%u baud",	PARAM_SPEED);
	print_param(fd, "txdelay",	"%u",  		PARAM_TXDELAY);
	print_param(fd, "persist",	"%u",		PARAM_PERSIST);
	print_param(fd, "slottime",	"%u",		PARAM_SLOTTIME);
	print_param(fd, "txtail",	"%u",		PARAM_TXTAIL);
	print_param(fd, "fulldup",	"%u",		PARAM_FULLDUP);
	print_param(fd, "waittime",	"%u",		PARAM_WAIT);
	print_param(fd, "mintime",	"%u sec",	PARAM_MIN);
	print_param(fd, "maxkeyup",	"%u sec",	PARAM_MAXKEY);
	print_param(fd, "idletime",	"%u sec",	PARAM_IDLE);
	print_param(fd, "maxdefer",	"%u sec",	PARAM_MAXDEFER);
	print_param(fd, "group",	"0x%2.2x",	PARAM_GROUP);
	print_param(fd, "txoff",	"*",		PARAM_TX);
	print_param(fd, "softdcd",	"*",		PARAM_SOFTDCD);



        printf("\nStatus:\n\n");
        printf("HDLC                  Z8530           Interrupts         Buffers\n");
        printf("-----------------------------------------------------------------------\n");
        printf("Sent       : %7lu  RxOver : %5u  RxInts : %8lu  Size    : %4u\n", stat.txframes, stat.rx_over, stat.rxints, stat.bufsize);
        printf("Received   : %7lu  TxUnder: %5u  TxInts : %8lu  NoSpace : %4u\n", stat.rxframes, stat.tx_under, stat.txints, stat.nospace);
        printf("RxErrors   : %7lu                  ExInts : %8lu\n", stat.rxerrs,   stat.exints);
	printf("TxErrors   : %7lu                  SpInts : %8lu\n", stat.txerrs, stat.spints);
	printf("Tx State   : %7s\n\n", get_tx_status(stat.tx_state));
}


/*
Driver     : z8530drv-3.0
Device     : scc0
Hardware   : data 300 ctrl 304 irq 10 clock 4915200 brand BAYCOM chip SCC 
	     vector 000 special 000 option 00
MODEM      : speed 9600 nrzi DPLL softdcd bufsize 386
Interrupts : rx 1234567 tx 1234567 ex 1234567 sp 1234567
Statistics : received 1234567 rxerrs 1234567 overruns  1234567
             sent     1234567 txerrs 1234567 underruns 1234567
             nospace 1234567 txstate idle
KISS-params: tx delay    16
             persistence 64
             slottime    20
             tailtime    2
             ...
*/

static void
print_proc_hardware(unsigned char *buf)
{
	char *board, dev[64];
	unsigned long data, ctrl, clock, vector, special;
	int irq, enh, option, brand;

	sscanf(buf, "%s %lx %lx %d %lu %x %d %lx %lx %x",
		dev, &data, &ctrl, &irq, &clock, &brand,
		&enh, &vector, &special, &option);
			
	switch(brand)
	{
		case PA0HZP: board = "PA0HZP";	break;
		case EAGLE : board = "Eagle";	break;
		case PC100:  board = "PC100";	break;
		case PRIMUS: board = "Primus";  break;
		case DRSI:   board = "DRSI";	break;
		case BAYCOM: board = "BayCom";	break;
		default:     board = "???";	break;
	}
	printf("Device     : %s\n", dev);
	printf("Hardware   : data %lx ctrl %lx irq %d clock %lu brand %s chip %s\n",
		data, ctrl, irq, clock, board, enh? "ESCC":"SCC");
		
	if (vector || special || option)
	{
		printf("             ");
		if (vector)
			printf("vector %lx ", vector);
		if (special)
			printf("special %lx ", special);
		if (option)
			printf("option %2.2x ", option);
		printf("\n");
	}
}

static void
print_proc_modem(unsigned char *buf)
{
	unsigned long speed;
	int nrz, clocksrc, softdcd, bufsize;
	char *ClockSource[] = {"DPLL","external", "divider", "???", "???"};

	sscanf(buf, "%lu %d %d %d %d", &speed, &nrz, &clocksrc, &softdcd, &bufsize);
	printf("MODEM      : speed %lu nrz%s %s %s bufsize %d\n",
		speed, nrz? "":"i", ClockSource[clocksrc], softdcd? "harddcd":"sofdcd", bufsize);
}

static void 
print_proc_interrupts(unsigned char *buf)
{
	unsigned long rxints, txints, exints, spints;
	sscanf(buf, "%lu %lu %lu %lu", &rxints, &txints, &exints, &spints);
	printf("Interrupts : rx %lu tx %lu ex %lu sp %lu\n", rxints, txints, exints, spints);
}

static void
print_proc_stat(unsigned char *buf)
{
	unsigned long rxframes, rxerrs, txframes, txerrs;
	int nospace, txstate, rxover, txunder;
	
	sscanf(buf, "%lu %lu %d / %lu %lu %d / %d %d", 
		&rxframes, &rxerrs, &rxover, &txframes, &txerrs, &txunder,
		&nospace, &txstate);
		
	printf("Statistics : received %lu rxerrs %lu overruns %d\n",  rxframes, rxerrs, rxover);
	printf("             sent     %lu txerrs %lu underruns %d\n", txframes, txerrs, txunder);
	printf("             nospace %d tx state %s\n", nospace, get_tx_status(txstate));
}

static void
print_proc_kiss(char *buf)
{
	int txd, pers, slot, tail, ful, wait, min, max, idle, defer, tx, grp;
	
	sscanf(buf, "%d %d %d %d %d %d %d %d %d %d %d %d", 
		&txd, &pers, &slot, &tail, &ful, &wait, &min, &max,
	        &idle, &defer, &tx, &grp);

	printf("KISS-params: tx delay    %d\n", txd);
	printf("             persistence %d\n", pers);
	printf("             slottime    %d\n", slot);
	printf("             tailtime    %d\n", tail);
	printf("             fullduplex  %d\n", ful);
	printf("             waittime    %d\n", wait);
	printf("             mintime     %d sec\n", min);
	printf("             maxkeyup    %d sec\n", max);
	printf("             idletime    %d sec\n", idle);
	printf("             maxdefer    %d sec\n", defer);
	printf("             txoff       %s\n", tx?"on":"off");
	printf("             group       0x%2.2x\n", grp);
}

static void
print_proc_wregs(char *buf)
{
	printf("Z8530 WRegs: %s", buf+2);
}

static void
print_proc_rregs(char *buf)
{
	printf("Z8530 RRegs: %s", buf+2);
}

static void
print_proc_debug(char *buf)
{
	printf("           : %s", buf);
}

#define MSG_NOTINIT	"not initialized"
#define MSG_NOCHIPS	"chips missing"

int print_proc_statistics(char *dev)
{
	FILE *fp;
	unsigned char buf[1024];
	int line_no = 0;
	
	if ((fp = fopen(PROCFILE, "r")) == NULL)
		return 1;
	
	if (fgets(buf, sizeof(buf), fp) == NULL)
		return 1;

	printf("Driver     : %s", buf);
	
	if (fgets(buf, sizeof(buf), fp) == NULL)
		return 1;
	
	if (!strncmp(buf, MSG_NOTINIT, strlen(MSG_NOTINIT)))
	{
		printf("Status     : the driver is not initialized.\n");
		return 1;
	}
		
	if (!strncmp(buf, MSG_NOCHIPS, strlen(MSG_NOCHIPS)))
	{
		printf("Status     : the driver did not find any chips.\n");
		return 1;
	}
		
	do
	{
		if (*buf != '\t' && *buf != ' ')
		{
			line_no = 0;
			if (strncmp(dev, buf, strlen(dev)))
				continue;
			print_proc_hardware(buf);
			line_no = 1;
			continue;
		}
		
		if (line_no == 0)
			continue;

		switch(line_no)
		{
			case 1:
				print_proc_modem(buf);
				break;
			case 2:
				print_proc_interrupts(buf);
				break;
			case 3:
				print_proc_stat(buf);
				break;
			case 4:
				print_proc_kiss(buf);
				break;
			case 5:
				print_proc_wregs(buf);
				break;
			case 6:
				print_proc_rregs(buf);
				break;
			default:
				print_proc_debug(buf);
		}
		line_no++;
	} while (fgets(buf, sizeof(buf), fp) != NULL);
	printf("\n");
	fclose(fp);
	return 0;
}

int main(int argc, char **argv)
{
	int fd, cnt;
	char dev[35], *p, *k;
	int error, proc = 0;
	
	check_version();

	if (argc == 1)
	{
		fprintf(stderr, "usage: %s [-p] dev [dev...]\n\n", argv[0]);
		exit(1);
	}

	for (cnt = 1; cnt < argc; cnt++)
	{
		if (!strcmp(argv[cnt], "-p"))
		{
			proc = 1;
			continue;
		}

		strcpy(dev, argv[cnt]);
		k = dev;
		p = strrchr(dev, '/');

		if (p == NULL) 
			p = dev;
		else
			p++;

		while (*p) *k++ = tolower(*p++);
		*k='\0';
		
		if (cnt-proc > 1)
			printf("--------------------\n");

		if (!proc || print_proc_statistics(dev))
		{
			char buf[40];
			sprintf(buf, "/dev/%s", dev);
			
			fd = socket(AF_AX25, SOCK_DGRAM, 0);
			
			strcpy(ifr.ifr_name, dev);
			ifr.ifr_data = (caddr_t) &stat;
			error = ioctl(fd, SIOCSCCGSTAT, &ifr);
			if (error < 0)
			{
				perror("SIOCSCCGSTAT: ");
				exit(1);
			}
		
			print_statistics(fd);
	
			close(fd);
		}
	}
	return 0;
}
