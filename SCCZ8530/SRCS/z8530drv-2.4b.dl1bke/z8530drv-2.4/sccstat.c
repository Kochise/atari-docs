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
#include <linux/scc.h>
#endif
#include <linux/fs.h>
#include <linux/tty.h>
#include <linux/if.h>
#include <linux/errno.h>

#define RCS_ID "$Id: sccstat.c,v 1.9 1995/11/17 01:10:36 jreuter Exp jreuter $"

struct ifreq ifr;
int is_socket = 0;
struct scc_stat stat;

void print_param(int fd, char *name, char *form, int command)
{
	struct scc_kiss_cmd kiss_cmd;
	char s[80];
	int error;
	
	kiss_cmd.command = command;
	
	if (is_socket)
	{
		ifr.ifr_data = (caddr_t) &kiss_cmd;
		error = ioctl(fd, SIOCSCCGKISS, &ifr);
	}
	else
		error = ioctl(fd, TIOCSCCGKISS, &kiss_cmd);
	
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
	char   txs[10];
	
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

	switch(stat.tx_state)
	{
		case	TXS_IDLE:
			strcpy(txs,"   idle");
			break;
		case	TXS_BUSY:
			strcpy(txs,"   busy");
			break;
		case	TXS_ACTIVE:
			strcpy(txs," active");
			break;
		case	TXS_NEWFRAME:
			strcpy(txs,"   kick");
			break;
		case	TXS_IDLE2:
			strcpy(txs,"  keyed");
			break;
		case	TXS_WAIT:
			strcpy(txs,"   wait");
			break;
		case	TXS_TIMEOUT:
			strcpy(txs,"timeout");
		default:
			strcpy(txs,"      ?");
			break;
	}

        printf("\nStatus:\n\n");
        printf("HDLC                  Z8530           Interrupts         Queues\n");
        printf("-----------------------------------------------------------------------\n");
        printf("Sent       : %7lu  RxOver : %5u  RxInts : %8lu  RxQueue : %4u\n", stat.txframes, stat.rx_over, stat.rxints, stat.rx_queued);
        printf("Received   : %7lu  TxUnder: %5u  TxInts : %8lu  TxQueue : %4u\n", stat.rxframes, stat.tx_under, stat.txints, stat.tx_queued);
        printf("RxErrors   : %7lu                  ExInts : %8lu  NoSpace : %4u\n", stat.rxerrs,   stat.exints, stat.nospace);
	printf("TxErrors   : %7lu                  SpInts : %8lu\n", stat.txerrs, stat.spints);
	printf("Tx State   : %s\n\n", txs);
	
	printf("Memory allocated:\n\n");
	
	printf("Buffer size: %4u\n",  stat.bufsize);
	printf("rx buffers : %4u\n",  stat.rxbuffers);
	printf("tx buffers : %4u\n\n",stat.txbuffers);
	
}

#define PROCFILE "/proc/net/z8530drv"

#define MSG_NOTINIT	"Driver not"
#define MSG_NOCHIPS	"Z8530 chips"
#define MSG_DEVICE	"Device"
#define MSG_HARDWARE	"Hardware"
#define MSG_RECEIVED	"Received"
#define MSG_TRANSMITTED "Transmitted"
#define MSG_INTERRUPTS	"Interrupts"
#define MSG_MEMINFO	"Buffers"
#define MSG_MODEM	"MODEM"
#define MSG_MODE	"Mode"
#define MSG_KISS	"KISS"

#define IS_SPACE(c) (c == ' ' || c == '\t')
#define IS_MSG(s)   !(strncmp(buf, s, sizeof(s)-1))

int print_proc_statistics(char *dev)
{
	FILE *fp;
	unsigned char buf[1024], *plist;
	int flag = 0;
	
	if ((fp = fopen(PROCFILE, "r")) == NULL)
		return 1;
	
	while (!feof(fp))
	{
		fgets(buf, sizeof(buf), fp);

		if (IS_MSG(MSG_NOTINIT))
		{
			printf("%s\n", buf);
			exit(1);
		}
		
		if (IS_MSG(MSG_NOCHIPS))
		{
			printf("%s\n", buf);
			exit(1);
		}
		
		if (strlen(buf) < 10)
			continue;
			
		buf[strlen(buf)-1] = '\0';

		plist = strchr(buf, ':');
		if (plist == NULL)
			continue;
		plist++;

		while (*plist && IS_SPACE(*plist)) plist++;
		
		if (*plist == '\0')
			continue;
			
		if (IS_MSG(MSG_DEVICE))
		{
			flag = 0;
			if (strcmp(plist, dev)) continue;
			printf("\nDevice     : %s\n", plist);
			flag = 1;
		}
		
		if (!flag)
			continue;

		if (IS_MSG(MSG_HARDWARE))
		{
			int irq, cmd, escc, data, ctrl, latch, special, k;
			unsigned long pclk;
			char hw[20], type[20];

			sscanf(plist, "%x %x %d %lu %s %s %x %x %d",
				&data, &ctrl, &irq, &pclk, hw, type,
				&latch, &special, &cmd);
				
			for (k = 0; k < strlen(hw); k++)
				hw[k] = toupper(hw[k]);

			escc = strcmp(type, "norm");
			
			printf("Hardware   : data %3.3x ctrl %3.3x irq %d pclk %lu vendor %s chip %s\n",
				data, ctrl, irq, pclk, hw, escc?"ESCC":"SCC");

			if (latch || special)
			{
				printf("             ");
				if (latch)
					printf("irq latch %3.3x ", latch);
				if (special)
					printf("special %3.3x opt %2.2x", special, cmd);
				printf("\n");
			}
			printf("\n");
		} else
		if (IS_MSG(MSG_RECEIVED))
		{
			unsigned long rcvd, errs;
			int over;

			sscanf(plist, "%lu %lu %d", &rcvd, &errs, &over);
			printf("Received   : %lu frames, %lu errors, %d overruns\n",
				rcvd, errs, over);
		} else
		if (IS_MSG(MSG_TRANSMITTED))
		{
			unsigned long sent, errs;
			int under;
			char state[20];

			sscanf(plist, "%lu %lu %d %s", &sent, &errs, &under, state);
			printf("Transmitted: %lu frames, %lu errors, %d underruns, state %s\n",
				sent, errs, under, state);
		} else
		if (IS_MSG(MSG_INTERRUPTS))
		{
			unsigned long rx, tx, ex, sp;
		
			sscanf(plist, "%lu %lu %lu %lu", &rx, &tx, &ex, &sp);
			printf("Interrupts : %lu rx, %lu tx, %lu ex, %lu sp\n", rx, tx, ex, sp);
			printf("\n");
		} else
		if (IS_MSG(MSG_MEMINFO))
		{
			int size, rxq, rxt, txq, txt, err;
			sscanf(plist, "%d %d/%d %d/%d %d", &size, &rxq, &rxt, &txq, &txt, &err);
			printf("MemInfo    : bufsize %d, %d/%d rx, %d/%d tx, %d dropped\n",
				size, rxq, rxt, txq, txt, err);
		} else
		if (IS_MSG(MSG_MODEM))
		{
			unsigned long speed;
			char nrzi[10], clksrc[15], dcd[10];
		
			sscanf(plist, "%lu %s %s %s", &speed, nrzi, clksrc, dcd);
			printf("MODEM      : speed %lu, source %s, %s mode, %sware DCD\n",
				speed, clksrc, nrzi, dcd);
		} else
		if (IS_MSG(MSG_MODE))
		{
			char drvmode[10];
			
			sscanf(plist, "%s", drvmode);
			printf("Mode       : %s\n", drvmode);
			printf("\n");
		} else
		if (IS_MSG(MSG_KISS))
		{
			int txd, p, slot, tail, ful, wait, min, max, idle;
			int defer, tx, grp;

			sscanf(plist, "%d %d %d %d %d %d %d %d %d %d %d %d", 
				       &txd, &p, &slot, &tail,
				       &ful, &wait, &min, &max,
				       &idle, &defer, &tx, &grp);
				       
			printf("KISS params: tx delay    %d\n", txd);
			printf("             persistence %d\n", p);
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
			printf("\n");
		}
	}
	fclose(fp);
	return 0;
}

int main(int argc, char **argv)
{
	int fd, cnt;
	char dev[35], *p, *k;
	int error, proc = 0;

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
			
			if (fd < 0)
				is_socket = 0;
			else {
				is_socket = 1;
				strcpy(ifr.ifr_name, dev);
				ifr.ifr_data = (caddr_t) &stat;
				error = ioctl(fd, SIOCSCCGSTAT, &ifr);
				if (error < 0)
				{
					if (cnt == 1)
						is_socket = 0;
					else
						perror("SIOCSCCGSTAT: ");
				}
			}

			if (!is_socket)
			{
				if ((fd = open(buf, O_RDWR)) < 0)
				{
					fprintf(stderr, "ERROR: Cannot open scc device %s", buf);
					perror("");
					exit(1);
				}
			}
		
			print_statistics(fd);
	
			close(fd);
		}
	}
	return 0;
}
